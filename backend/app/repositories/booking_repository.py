import random
import secrets
import uuid
from datetime import datetime, time, timezone
from decimal import Decimal
from typing import List, Optional, Tuple
from sqlalchemy import desc, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.schema_models import (
    Booking,
    BookingStatus,
    BookingStatusHistory,
    CreatorProfile,
    Package,
    Review,
    User,
)
from app.repositories.base import BaseRepository


class BookingRepository(BaseRepository[Booking]):
    def __init__(self, db: AsyncSession):
        super().__init__(Booking, db)

    async def generate_booking_code(self) -> str:
        """Generate human-friendly booking code like IR-2026-ABCD."""
        year = datetime.now(timezone.utc).year
        suffix = secrets.token_hex(2).upper()
        return f"IR-{year}-{suffix}"

    async def create_booking(self, booking: Booking) -> Booking:
        """Atomically create booking and initial status history audit entry."""
        if not booking.booking_code:
            booking.booking_code = await self.generate_booking_code()

        self.db.add(booking)
        await self.db.flush()

        initial_history = BookingStatusHistory(
            booking_id=booking.id,
            status=booking.status,
            note="Booking created by customer.",
            changed_by_user_id=booking.customer_id,
        )
        self.db.add(initial_history)
        await self.db.commit()
        await self.db.refresh(booking)
        return booking

    async def get_by_code(self, booking_code: str) -> Optional[Booking]:
        query = (
            select(Booking)
            .options(
                selectinload(Booking.customer),
                selectinload(Booking.creator),
                selectinload(Booking.package),
                selectinload(Booking.status_history),
                selectinload(Booking.review),
            )
            .where(
                Booking.booking_code == booking_code.strip().upper(),
                Booking.is_deleted == False,  # noqa: E712
            )
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def get_by_id_with_details(self, booking_id: uuid.UUID) -> Optional[Booking]:
        query = (
            select(Booking)
            .options(
                selectinload(Booking.customer),
                selectinload(Booking.creator),
                selectinload(Booking.package),
                selectinload(Booking.status_history),
                selectinload(Booking.payments),
                selectinload(Booking.review),
            )
            .where(
                Booking.id == booking_id,
                Booking.is_deleted == False,  # noqa: E712
            )
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def update_status(
        self,
        booking_id: uuid.UUID,
        new_status: BookingStatus,
        note: Optional[str] = None,
        changed_by_user_id: Optional[uuid.UUID] = None,
        reel_url: Optional[str] = None,
    ) -> Optional[Booking]:
        """Update booking status and log to audit history."""
        booking = await self.get_by_id(booking_id)
        if not booking:
            return None

        if new_status in (BookingStatus.DELIVERED, BookingStatus.DELIVERED_ON_WHATSAPP):
            booking.delivered_at = datetime.now(timezone.utc)
            booking.delivery_status = "delivered"
            if reel_url:
                booking.reel_url = reel_url

        # Log history
        history = BookingStatusHistory(
            booking_id=booking.id,
            status=new_status,
            note=note,
            changed_by_user_id=changed_by_user_id,
        )
        self.db.add(history)

        await self.db.commit()
        await self.db.refresh(booking)
        return booking

    async def get_customer_bookings(
        self,
        customer_id: uuid.UUID,
        limit: int = 50,
    ) -> List[Booking]:
        query = (
            select(Booking)
            .options(
                selectinload(Booking.package),
                selectinload(Booking.creator),
            )
            .where(
                Booking.customer_id == customer_id,
                Booking.is_deleted == False,  # noqa: E712
            )
            .order_by(desc(Booking.created_at))
            .limit(limit)
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_creator_bookings(
        self,
        creator_id: uuid.UUID,
        tab: str = "all",
        limit: int = 50,
    ) -> List[Booking]:
        """Fetch creator bookings based on workflow tabs: today, active, completed, all."""
        query = (
            select(Booking)
            .options(
                selectinload(Booking.package),
                selectinload(Booking.customer),
                selectinload(Booking.status_history),
            )
            .where(
                Booking.is_deleted == False,  # noqa: E712
            )
        )

        now_utc = datetime.now(timezone.utc)
        today_start = datetime.combine(now_utc.date(), time.min, tzinfo=timezone.utc)
        today_end = datetime.combine(now_utc.date(), time.max, tzinfo=timezone.utc)

        active_statuses = [
            BookingStatus.ASSIGNED,
            BookingStatus.ON_THE_WAY,
            BookingStatus.REACHED,
            BookingStatus.SHOOTING_STARTED,
            BookingStatus.SHOOTING_COMPLETED,
            BookingStatus.EDITING_STARTED,
            BookingStatus.EDITING_COMPLETED,
            BookingStatus.CREATOR_ASSIGNED,
            BookingStatus.ARRIVED_AT_LOCATION,
            BookingStatus.SHOOTING_IN_PROGRESS,
            BookingStatus.EDITING,
        ]

        completed_statuses = [
            BookingStatus.DELIVERED,
            BookingStatus.COMPLETED,
            BookingStatus.DELIVERED_ON_WHATSAPP,
        ]

        if tab == "available":
            query = query.where(
                Booking.creator_id.is_(None),
                Booking.status == BookingStatus.PENDING,
            )
        elif tab == "today":
            query = query.where(
                Booking.creator_id == creator_id,
                Booking.scheduled_at >= today_start,
                Booking.scheduled_at <= today_end,
            )
        elif tab == "active":
            query = query.where(
                Booking.creator_id == creator_id,
                Booking.status.in_(active_statuses),
            )
        elif tab == "completed":
            query = query.where(
                Booking.creator_id == creator_id,
                Booking.status.in_(completed_statuses),
            )
        else:
            query = query.where(Booking.creator_id == creator_id)

        query = query.order_by(desc(Booking.scheduled_at)).limit(limit)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_creator_dashboard_stats(self, creator_user_id: uuid.UUID) -> dict:
        """Compute live dashboard metrics: today's bookings, completed, earnings, rating."""
        now_utc = datetime.now(timezone.utc)
        today_start = datetime.combine(now_utc.date(), time.min, tzinfo=timezone.utc)
        today_end = datetime.combine(now_utc.date(), time.max, tzinfo=timezone.utc)

        completed_statuses = [
            BookingStatus.DELIVERED,
            BookingStatus.COMPLETED,
            BookingStatus.DELIVERED_ON_WHATSAPP,
        ]

        # 1. Today's Bookings
        today_query = (
            select(Booking)
            .options(
                selectinload(Booking.package),
                selectinload(Booking.customer),
            )
            .where(
                Booking.creator_id == creator_user_id,
                Booking.scheduled_at >= today_start,
                Booking.scheduled_at <= today_end,
                Booking.is_deleted == False,  # noqa: E712
            )
            .order_by(Booking.scheduled_at.asc())
        )
        today_res = await self.db.execute(today_query)
        today_bookings = list(today_res.scalars().all())

        # 2. Completed count
        completed_count_query = (
            select(func.count(Booking.id))
            .where(
                Booking.creator_id == creator_user_id,
                Booking.status.in_(completed_statuses),
                Booking.is_deleted == False,  # noqa: E712
            )
        )
        completed_count_res = await self.db.execute(completed_count_query)
        completed_count = completed_count_res.scalar() or 0

        # 3. Total Earnings
        earnings_query = (
            select(func.coalesce(func.sum(Package.price), 0))
            .select_from(Booking)
            .join(Package, Booking.package_id == Package.id)
            .where(
                Booking.creator_id == creator_user_id,
                Booking.status.in_(completed_statuses),
                Booking.is_deleted == False,  # noqa: E712
            )
        )
        earnings_res = await self.db.execute(earnings_query)
        total_earnings = Decimal(str(earnings_res.scalar() or 0))

        # 4. Today's Earnings
        today_earnings_query = (
            select(func.coalesce(func.sum(Package.price), 0))
            .select_from(Booking)
            .join(Package, Booking.package_id == Package.id)
            .where(
                Booking.creator_id == creator_user_id,
                Booking.status.in_(completed_statuses),
                Booking.delivered_at >= today_start,
                Booking.delivered_at <= today_end,
                Booking.is_deleted == False,  # noqa: E712
            )
        )
        today_earnings_res = await self.db.execute(today_earnings_query)
        today_earnings = Decimal(str(today_earnings_res.scalar() or 0))

        # 5. Creator Profile & Rating
        profile_query = (
            select(CreatorProfile)
            .where(
                CreatorProfile.user_id == creator_user_id,
                CreatorProfile.is_deleted == False,  # noqa: E712
            )
        )
        profile_res = await self.db.execute(profile_query)
        profile = profile_res.scalar_one_or_none()

        reviews_count_query = (
            select(func.count(Review.id))
            .where(
                Review.creator_id == creator_user_id,
                Review.is_deleted == False,  # noqa: E712
            )
        )
        reviews_res = await self.db.execute(reviews_count_query)
        total_reviews = reviews_res.scalar() or 0

        return {
            "today_bookings_count": len(today_bookings),
            "completed_bookings_count": completed_count,
            "today_earnings": today_earnings,
            "total_earnings": total_earnings,
            "rating_avg": profile.rating_avg if profile else Decimal("5.00"),
            "total_reviews": total_reviews,
            "is_available": profile.is_available if profile else True,
            "primary_city": profile.primary_city if profile else None,
            "today_bookings": today_bookings,
        }

    async def accept_booking(
        self,
        booking_id: uuid.UUID,
        creator_user_id: uuid.UUID,
    ) -> Optional[Booking]:
        """Creator accepts an unassigned or assigned booking."""
        booking = await self.get_by_id_with_details(booking_id)
        if not booking:
            return None

        booking.creator_id = creator_user_id
        booking.status = BookingStatus.ASSIGNED

        history = BookingStatusHistory(
            booking_id=booking.id,
            status=BookingStatus.ASSIGNED,
            note="Booking accepted by creator",
            changed_by_user_id=creator_user_id,
        )
        self.db.add(history)
        await self.db.commit()
        await self.db.refresh(booking)
        return booking

    async def reject_booking(
        self,
        booking_id: uuid.UUID,
        creator_user_id: uuid.UUID,
        reason: Optional[str] = None,
    ) -> Optional[Booking]:
        """Creator rejects a booking. Unassigns and resets to pending for other creators."""
        booking = await self.get_by_id_with_details(booking_id)
        if not booking:
            return None

        note_text = f"Booking declined by creator: {reason}" if reason else "Booking declined by creator"
        history = BookingStatusHistory(
            booking_id=booking.id,
            status=BookingStatus.REJECTED,
            note=note_text,
            changed_by_user_id=creator_user_id,
        )
        self.db.add(history)

        # Release assignment back to pool
        booking.creator_id = None
        booking.status = BookingStatus.PENDING

        await self.db.commit()
        await self.db.refresh(booking)
        return booking

    async def update_creator_status(
        self,
        booking_id: uuid.UUID,
        creator_user_id: uuid.UUID,
        new_status: BookingStatus,
        note: Optional[str] = None,
        reel_url: Optional[str] = None,
    ) -> Optional[Booking]:
        """Update booking status through the creator workflow stages."""
        booking = await self.get_by_id_with_details(booking_id)
        if not booking:
            return None

        booking.status = new_status
        if new_status in (BookingStatus.DELIVERED, BookingStatus.DELIVERED_ON_WHATSAPP):
            booking.delivered_at = datetime.now(timezone.utc)
            booking.delivery_status = "delivered"
            if reel_url:
                booking.reel_url = reel_url

        history = BookingStatusHistory(
            booking_id=booking.id,
            status=new_status,
            note=note or f"Status advanced to {new_status.value}",
            changed_by_user_id=creator_user_id,
        )
        self.db.add(history)

        await self.db.commit()
        await self.db.refresh(booking)
        return booking

    async def search_bookings(
        self,
        customer_id: Optional[uuid.UUID] = None,
        creator_id: Optional[uuid.UUID] = None,
        city: Optional[str] = None,
        status: Optional[BookingStatus] = None,
        search_query: Optional[str] = None,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
        skip: int = 0,
        limit: int = 20,
    ) -> Tuple[List[Booking], int]:
        """Comprehensive search and filter for bookings management."""
        query = (
            select(Booking)
            .options(
                selectinload(Booking.package),
                selectinload(Booking.customer),
                selectinload(Booking.creator),
                selectinload(Booking.status_history),
            )
            .where(Booking.is_deleted == False)  # noqa: E712
        )

        count_query = select(func.count(Booking.id)).where(Booking.is_deleted == False)  # noqa: E712

        if customer_id:
            query = query.where(Booking.customer_id == customer_id)
            count_query = count_query.where(Booking.customer_id == customer_id)

        if creator_id:
            query = query.where(Booking.creator_id == creator_id)
            count_query = count_query.where(Booking.creator_id == creator_id)

        if city:
            query = query.where(func.lower(Booking.city) == city.strip().lower())
            count_query = count_query.where(func.lower(Booking.city) == city.strip().lower())

        if status:
            query = query.where(Booking.status == status)
            count_query = count_query.where(Booking.status == status)

        if date_from:
            query = query.where(Booking.scheduled_at >= date_from)
            count_query = count_query.where(Booking.scheduled_at >= date_from)

        if date_to:
            query = query.where(Booking.scheduled_at <= date_to)
            count_query = count_query.where(Booking.scheduled_at <= date_to)

        if search_query:
            term = f"%{search_query.strip()}%"
            search_filter = or_(
                Booking.booking_code.ilike(term),
                Booking.location_address.ilike(term),
                Booking.city.ilike(term),
                Booking.notes.ilike(term),
            )
            query = query.where(search_filter)
            count_query = count_query.where(search_filter)

        total_res = await self.db.execute(count_query)
        total = total_res.scalar() or 0

        query = query.order_by(desc(Booking.created_at)).offset(skip).limit(limit)
        result = await self.db.execute(query)
        bookings = list(result.scalars().all())

        return bookings, total

    async def assign_creator(
        self,
        booking_id: uuid.UUID,
        creator_id: uuid.UUID,
        assigned_by_id: uuid.UUID,
        note: Optional[str] = None,
    ) -> Optional[Booking]:
        """Assign creator to booking and log audit history."""
        booking = await self.get_by_id_with_details(booking_id)
        if not booking:
            return None

        booking.creator_id = creator_id
        booking.status = BookingStatus.ASSIGNED

        audit_note = note or "Creator assigned to booking"
        history = BookingStatusHistory(
            booking_id=booking.id,
            status=BookingStatus.ASSIGNED,
            note=audit_note,
            changed_by_user_id=assigned_by_id,
        )
        self.db.add(history)
        await self.db.commit()
        await self.db.refresh(booking)
        return booking

    async def cancel_booking(
        self,
        booking_id: uuid.UUID,
        cancelled_by_id: uuid.UUID,
        reason: str,
        note: Optional[str] = None,
    ) -> Optional[Booking]:
        """Cancel booking with audit reason and attribution."""
        booking = await self.get_by_id_with_details(booking_id)
        if not booking:
            return None

        booking.status = BookingStatus.CANCELLED

        combined_note = f"Reason: {reason}. {note or ''}".strip()
        history = BookingStatusHistory(
            booking_id=booking.id,
            status=BookingStatus.CANCELLED,
            note=combined_note,
            changed_by_user_id=cancelled_by_id,
        )
        self.db.add(history)
        await self.db.commit()
        await self.db.refresh(booking)
        return booking

    async def get_status_timeline(
        self,
        booking_id: uuid.UUID,
    ) -> List[BookingStatusHistory]:
        """Fetch complete chronological audit status transitions."""
        query = (
            select(BookingStatusHistory)
            .options(selectinload(BookingStatusHistory.changed_by))
            .where(
                BookingStatusHistory.booking_id == booking_id,
                BookingStatusHistory.is_deleted == False,  # noqa: E712
            )
            .order_by(BookingStatusHistory.created_at.asc())
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())


