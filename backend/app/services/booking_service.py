import uuid
from datetime import datetime, timezone
from typing import List, Optional, Tuple
from fastapi import status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppException, ForbiddenException, NotFoundException
from app.models.schema_models import (
    Booking,
    BookingStatus,
    CreatorProfile,
    Notification,
    Package,
    User,
    UserRole,
)
from app.repositories.booking_repository import BookingRepository
from app.repositories.creator_repository import CreatorRepository
from app.repositories.package_repository import PackageRepository
from app.schemas.booking import BookingCreateRequest
from app.schemas.booking_management import (
    BookingTimelineItem,
    BookingTimelineResponse,
)

SUPPORTED_CITIES = {"maripeda", "mahabubabad", "khammam", "warangal"}

STATUS_TITLES = {
    BookingStatus.PENDING: "Booking Requested",
    BookingStatus.ASSIGNED: "Creator Assigned",
    BookingStatus.ON_THE_WAY: "Creator On The Way",
    BookingStatus.REACHED: "Creator Reached Venue",
    BookingStatus.SHOOTING_STARTED: "Shooting In Progress",
    BookingStatus.SHOOTING_COMPLETED: "Shooting Completed",
    BookingStatus.EDITING_STARTED: "10-Minute Rapid Edit Started",
    BookingStatus.EDITING_COMPLETED: "Editing Completed",
    BookingStatus.DELIVERED: "Reel Delivered via WhatsApp",
    BookingStatus.COMPLETED: "Booking Completed",
    BookingStatus.CANCELLED: "Booking Cancelled",
    BookingStatus.REJECTED: "Creator Declined Assignment",
    # Legacy
    BookingStatus.CREATOR_ASSIGNED: "Creator Assigned",
    BookingStatus.ARRIVED_AT_LOCATION: "Creator Reached Venue",
    BookingStatus.SHOOTING_IN_PROGRESS: "Shooting In Progress",
    BookingStatus.EDITING: "Editing",
    BookingStatus.DELIVERED_ON_WHATSAPP: "Reel Delivered via WhatsApp",
}


class BookingService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.booking_repo = BookingRepository(db)
        self.package_repo = PackageRepository(db)
        self.creator_repo = CreatorRepository(db)

    async def create_booking(
        self,
        customer: User,
        payload: BookingCreateRequest,
    ) -> Booking:
        """Domain logic for creating a booking."""
        # 1. Validate package
        package = await self.package_repo.get_by_id(payload.package_id)
        if not package or not package.is_active:
            raise NotFoundException("Selected package is invalid or currently unavailable")

        # 2. Validate city
        normalized_city = payload.city.strip().lower()
        if normalized_city not in SUPPORTED_CITIES:
            raise AppException(
                f"City '{payload.city}' is outside active hubs. We currently service Maripeda, Mahabubabad, Khammam, and Warangal.",
                status_code=status.HTTP_400_BAD_REQUEST,
                code="UNSUPPORTED_LOCATION",
            )

        # 3. Build booking record
        event_label = payload.event_type.display_name
        combined_notes = f"Event: {event_label}. {payload.notes or ''}".strip()

        booking = Booking(
            customer_id=customer.id,
            package_id=package.id,
            city=payload.city.strip(),
            location_address=payload.location_address.strip(),
            latitude=payload.latitude,
            longitude=payload.longitude,
            scheduled_at=payload.scheduled_at,
            customer_whatsapp=payload.customer_whatsapp.strip(),
            notes=combined_notes,
            status=BookingStatus.PENDING,
        )

        created = await self.booking_repo.create_booking(booking)

        # 4. Trigger in-app notification
        notification = Notification(
            user_id=customer.id,
            title="Shoot Reserved! 🎬",
            body=f"Booking {created.booking_code} placed in {created.city}. We are assigning your local videographer.",
            type="booking_created",
            data={"booking_id": str(created.id), "code": created.booking_code},
        )
        self.db.add(notification)
        await self.db.commit()

        detailed = await self.booking_repo.get_by_id_with_details(created.id)
        return detailed or created

    async def assign_creator(
        self,
        booking_id: uuid.UUID,
        creator_id: uuid.UUID,
        assigned_by: User,
        note: Optional[str] = None,
    ) -> Booking:
        """Domain logic for booking assignment."""
        booking = await self.booking_repo.get_by_id_with_details(booking_id)
        if not booking:
            raise NotFoundException("Booking not found")

        assignable_statuses = {
            BookingStatus.PENDING,
            BookingStatus.REJECTED,
            BookingStatus.ASSIGNED,
            BookingStatus.CREATOR_ASSIGNED,
        }
        if booking.status not in assignable_statuses:
            raise AppException(
                f"Cannot reassign booking at stage '{booking.status.value}'. Shoot is already active.",
                status_code=status.HTTP_400_BAD_REQUEST,
                code="INVALID_ASSIGNMENT_STAGE",
            )

        # Validate creator user
        res = await self.db.execute(select(User).where(User.id == creator_id))
        creator_user = res.scalar_one_or_none()
        if not creator_user or creator_user.role not in (UserRole.CREATOR, UserRole.ADMIN):
            raise AppException(
                "Specified user is not registered as a Creator.",
                status_code=status.HTTP_400_BAD_REQUEST,
                code="INVALID_CREATOR",
            )

        updated = await self.booking_repo.assign_creator(
            booking_id=booking.id,
            creator_id=creator_user.id,
            assigned_by_id=assigned_by.id,
            note=note,
        )

        # Notifications
        creator_notif = Notification(
            user_id=creator_user.id,
            title="New Shoot Assignment! 📸",
            body=f"You have been assigned to booking {booking.booking_code} in {booking.city}.",
            type="booking_assigned",
            data={"booking_id": str(booking.id), "code": booking.booking_code},
        )
        customer_notif = Notification(
            user_id=booking.customer_id,
            title="Creator Assigned! 🚀",
            body=f"{creator_user.name or 'A videographer'} has been assigned to your {booking.city} shoot.",
            type="creator_assigned",
            data={"booking_id": str(booking.id), "code": booking.booking_code},
        )
        self.db.add(creator_notif)
        self.db.add(customer_notif)
        await self.db.commit()

        detailed = await self.booking_repo.get_by_id_with_details(updated.id)
        return detailed or updated

    async def cancel_booking(
        self,
        booking_id: uuid.UUID,
        cancelled_by: User,
        reason: str,
        note: Optional[str] = None,
    ) -> Booking:
        """Domain logic for booking cancellation enforcement."""
        booking = await self.booking_repo.get_by_id_with_details(booking_id)
        if not booking:
            raise NotFoundException("Booking not found")

        # Check permissions
        is_customer = booking.customer_id == cancelled_by.id
        is_creator = booking.creator_id == cancelled_by.id
        is_admin = cancelled_by.role == UserRole.ADMIN

        if not (is_customer or is_creator or is_admin):
            raise ForbiddenException("You are not authorized to cancel this booking")

        # Cancellation policy locks
        terminal_statuses = {
            BookingStatus.CANCELLED,
            BookingStatus.DELIVERED,
            BookingStatus.COMPLETED,
            BookingStatus.DELIVERED_ON_WHATSAPP,
        }
        if booking.status in terminal_statuses:
            raise AppException(
                f"Booking is already in terminal state '{booking.status.value}' and cannot be cancelled.",
                status_code=status.HTTP_400_BAD_REQUEST,
                code="ALREADY_TERMINAL",
            )

        # If customer is cancelling, lock once creator is on the way or reached
        locked_from_customer = {
            BookingStatus.ON_THE_WAY,
            BookingStatus.REACHED,
            BookingStatus.SHOOTING_STARTED,
            BookingStatus.SHOOTING_COMPLETED,
            BookingStatus.EDITING_STARTED,
            BookingStatus.EDITING_COMPLETED,
            BookingStatus.ARRIVED_AT_LOCATION,
            BookingStatus.SHOOTING_IN_PROGRESS,
            BookingStatus.EDITING,
        }
        if is_customer and not is_admin and booking.status in locked_from_customer:
            raise AppException(
                "Videographer is already on location or travelling with gear. Please call support or videographer directly.",
                status_code=status.HTTP_400_BAD_REQUEST,
                code="CANCELLATION_LOCKED",
            )

        updated = await self.booking_repo.cancel_booking(
            booking_id=booking.id,
            cancelled_by_id=cancelled_by.id,
            reason=reason,
            note=note,
        )

        # Notify participants
        notif = Notification(
            user_id=booking.customer_id,
            title="Booking Cancelled",
            body=f"Booking {booking.booking_code} was cancelled. Reason: {reason}",
            type="booking_cancelled",
            data={"booking_id": str(booking.id)},
        )
        self.db.add(notif)
        if booking.creator_id:
            c_notif = Notification(
                user_id=booking.creator_id,
                title="Booking Cancelled",
                body=f"Booking {booking.booking_code} was cancelled by {cancelled_by.name or 'client'}.",
                type="booking_cancelled",
                data={"booking_id": str(booking.id)},
            )
            self.db.add(c_notif)
        await self.db.commit()

        detailed = await self.booking_repo.get_by_id_with_details(updated.id)
        return detailed or updated

    async def get_booking_timeline(
        self,
        booking_id: uuid.UUID,
        requesting_user: User,
    ) -> BookingTimelineResponse:
        """Generate structured status timeline with audit history."""
        booking = await self.booking_repo.get_by_id_with_details(booking_id)
        if not booking:
            raise NotFoundException("Booking not found")

        # Authorization check
        is_participant = (
            booking.customer_id == requesting_user.id
            or booking.creator_id == requesting_user.id
            or requesting_user.role == UserRole.ADMIN
        )
        if not is_participant:
            raise ForbiddenException("Access unauthorized to booking timeline")

        history_items = await self.booking_repo.get_status_timeline(booking_id)

        events: List[BookingTimelineItem] = []
        for h in history_items:
            h_status = h.status
            title = STATUS_TITLES.get(h_status, h_status.value.replace("_", " ").title())
            is_curr = h_status == booking.status

            changed_by_name = h.changed_by.name if h.changed_by else None
            changed_by_role = h.changed_by.role.value if h.changed_by else None

            events.append(
                BookingTimelineItem(
                    status=h_status.value,
                    title=title,
                    note=h.note,
                    changed_by_id=h.changed_by_user_id,
                    changed_by_name=changed_by_name,
                    changed_by_role=changed_by_role,
                    timestamp=h.created_at,
                    is_current=is_curr,
                    is_completed=True,
                )
            )

        return BookingTimelineResponse(
            booking_id=booking.id,
            booking_code=booking.booking_code,
            current_status=booking.status.value,
            city=booking.city,
            location_address=booking.location_address,
            customer_name=booking.customer.name if booking.customer else None,
            creator_name=booking.creator.name if booking.creator else None,
            scheduled_at=booking.scheduled_at,
            delivered_at=booking.delivered_at,
            reel_url=booking.reel_url,
            events=events,
        )

    async def get_filtered_bookings(
        self,
        user: User,
        status_val: Optional[BookingStatus] = None,
        city: Optional[str] = None,
        search_query: Optional[str] = None,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
        skip: int = 0,
        limit: int = 20,
    ) -> Tuple[List[Booking], int]:
        """Role-governed filtered bookings list."""
        customer_id = None
        creator_id = None

        if user.role == UserRole.CUSTOMER:
            customer_id = user.id
        elif user.role == UserRole.CREATOR:
            creator_id = user.id

        return await self.booking_repo.search_bookings(
            customer_id=customer_id,
            creator_id=creator_id,
            city=city,
            status=status_val,
            search_query=search_query,
            date_from=date_from,
            date_to=date_to,
            skip=skip,
            limit=limit,
        )
