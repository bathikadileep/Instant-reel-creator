import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.core.exceptions import AppException, ForbiddenException, NotFoundException
from app.models.schema_models import Booking, BookingStatus, Notification, User
from app.repositories.booking_repository import BookingRepository
from app.repositories.package_repository import PackageRepository
from app.schemas.booking import BookingCreateRequest, BookingResponse

router = APIRouter()


@router.post(
    "/",
    response_model=BookingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Reel Booking",
    description="Customer books a reel creator for Maripeda, Mahabubabad, Khammam, or Warangal.",
)
async def create_booking(
    payload: BookingCreateRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    pkg_repo = PackageRepository(db)
    pkg = await pkg_repo.get_by_id(payload.package_id)
    if not pkg or not pkg.is_active:
        raise NotFoundException("Selected package is invalid or currently unavailable")

    booking_repo = BookingRepository(db)

    # Format notes to embed event type cleanly
    event_label = payload.event_type.display_name
    combined_notes = f"Event: {event_label}. {payload.notes or ''}".strip()

    booking = Booking(
        customer_id=current_user.id,
        package_id=payload.package_id,
        city=payload.city,
        location_address=payload.location_address,
        latitude=payload.latitude,
        longitude=payload.longitude,
        scheduled_at=payload.scheduled_at,
        customer_whatsapp=payload.customer_whatsapp,
        notes=combined_notes,
        status=BookingStatus.PENDING,
    )

    created_booking = await booking_repo.create_booking(booking)

    # Trigger In-App Notification
    notification = Notification(
        user_id=current_user.id,
        title="Booking Confirmed! 🎬",
        body=f"Your booking {created_booking.booking_code} in {created_booking.city} has been placed. We are assigning your local Reel Creator.",
        type="booking_created",
        data={"booking_id": str(created_booking.id), "code": created_booking.booking_code},
    )
    db.add(notification)
    await db.commit()

    # Refetch with eager-loaded details
    detailed = await booking_repo.get_by_id_with_details(created_booking.id)
    return BookingResponse.model_validate(detailed)


@router.get(
    "/my-bookings",
    response_model=List[BookingResponse],
    status_code=status.HTTP_200_OK,
    summary="List Active Bookings",
    description="Returns active, ongoing, and scheduled bookings for the authenticated customer.",
)
async def get_active_bookings(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> List[BookingResponse]:
    booking_repo = BookingRepository(db)
    all_bookings = await booking_repo.get_customer_bookings(current_user.id)

    # Filter for active stages
    active_statuses = {
        BookingStatus.PENDING,
        BookingStatus.CREATOR_ASSIGNED,
        BookingStatus.ARRIVED_AT_LOCATION,
        BookingStatus.SHOOTING_IN_PROGRESS,
        BookingStatus.EDITING,
    }

    active_list = [b for b in all_bookings if b.status in active_statuses]
    # For full details, fetch with relations
    results = []
    for b in active_list:
        detailed = await booking_repo.get_by_id_with_details(b.id)
        if detailed:
            results.append(BookingResponse.model_validate(detailed))
    return results


@router.get(
    "/history",
    response_model=List[BookingResponse],
    status_code=status.HTTP_200_OK,
    summary="List Booking History",
    description="Returns completed, delivered, and cancelled bookings for the customer.",
)
async def get_booking_history(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> List[BookingResponse]:
    booking_repo = BookingRepository(db)
    all_bookings = await booking_repo.get_customer_bookings(current_user.id)

    history_statuses = {
        BookingStatus.DELIVERED_ON_WHATSAPP,
        BookingStatus.COMPLETED,
        BookingStatus.CANCELLED,
    }

    history_list = [b for b in all_bookings if b.status in history_statuses]
    results = []
    for b in history_list:
        detailed = await booking_repo.get_by_id_with_details(b.id)
        if detailed:
            results.append(BookingResponse.model_validate(detailed))
    return results


@router.get(
    "/{booking_id}",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Booking Details with Status Timeline",
)
async def get_booking_detail(
    booking_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    booking_repo = BookingRepository(db)
    booking = await booking_repo.get_by_id_with_details(booking_id)

    if not booking:
        raise NotFoundException("Booking not found")

    if booking.customer_id != current_user.id and current_user.role != "admin":
        raise ForbiddenException("Access to this booking is unauthorized")

    return BookingResponse.model_validate(booking)


@router.post(
    "/{booking_id}/cancel",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel Booking",
)
async def cancel_booking(
    booking_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    booking_repo = BookingRepository(db)
    booking = await booking_repo.get_by_id(booking_id)

    if not booking:
        raise NotFoundException("Booking not found")

    if booking.customer_id != current_user.id and current_user.role != "admin":
        raise ForbiddenException("Unauthorized to cancel this booking")

    if booking.status not in (BookingStatus.PENDING, BookingStatus.CREATOR_ASSIGNED):
        raise AppException(
            f"Cannot cancel booking at stage '{booking.status.value}'. Shoot is already in progress or completed.",
            status_code=status.HTTP_400_BAD_REQUEST,
            code="CANNOT_CANCEL",
        )

    updated = await booking_repo.update_status(
        booking_id=booking.id,
        new_status=BookingStatus.CANCELLED,
        note="Cancelled by customer",
        changed_by_user_id=current_user.id,
    )
    detailed = await booking_repo.get_by_id_with_details(updated.id)
    return BookingResponse.model_validate(detailed)
