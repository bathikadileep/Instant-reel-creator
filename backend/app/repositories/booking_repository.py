import random
import secrets
import uuid
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.schema_models import (
    Booking,
    BookingStatus,
    BookingStatusHistory,
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

        booking.status = new_status
        if new_status == BookingStatus.DELIVERED_ON_WHATSAPP:
            booking.delivered_at = datetime.now(timezone.utc)
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
        status: Optional[BookingStatus] = None,
        limit: int = 50,
    ) -> List[Booking]:
        query = (
            select(Booking)
            .options(
                selectinload(Booking.package),
                selectinload(Booking.customer),
            )
            .where(
                Booking.creator_id == creator_id,
                Booking.is_deleted == False,  # noqa: E712
            )
        )
        if status:
            query = query.where(Booking.status == status)

        query = query.order_by(desc(Booking.scheduled_at)).limit(limit)
        result = await self.db.execute(query)
        return list(result.scalars().all())
