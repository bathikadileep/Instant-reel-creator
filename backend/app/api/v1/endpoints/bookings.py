import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_active_user, require_admin
from app.core.database import get_db
from app.core.exceptions import ForbiddenException, NotFoundException
from app.models.schema_models import BookingStatus, User, UserRole
from app.schemas.booking import BookingCreateRequest, BookingResponse
from app.schemas.booking_management import (
    AssignCreatorRequest,
    BookingListResponse,
    BookingTimelineResponse,
    CancelBookingRequest,
)
from app.services.booking_service import BookingService

router = APIRouter()


@router.post(
    "/",
    response_model=BookingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Reel Booking",
    description="Customer books a reel videographer for Maripeda, Mahabubabad, Khammam, or Warangal.",
)
async def create_booking(
    payload: BookingCreateRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    service = BookingService(db)
    booking = await service.create_booking(customer=current_user, payload=payload)
    return BookingResponse.model_validate(booking)


@router.get(
    "/",
    response_model=BookingListResponse,
    status_code=status.HTTP_200_OK,
    summary="List & Filter Bookings",
    description="Search and filter bookings with pagination. Accessible to customer, creator, and admin.",
)
async def list_bookings(
    status_filter: Optional[BookingStatus] = Query(None, alias="status"),
    city: Optional[str] = Query(None, description="Filter by city: Maripeda, Mahabubabad, Khammam, Warangal"),
    search: Optional[str] = Query(None, description="Search by code, address, or customer note"),
    date_from: Optional[datetime] = Query(None),
    date_to: Optional[datetime] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> BookingListResponse:
    service = BookingService(db)
    items, total = await service.get_filtered_bookings(
        user=current_user,
        status_val=status_filter,
        city=city,
        search_query=search,
        date_from=date_from,
        date_to=date_to,
        skip=skip,
        limit=limit,
    )
    return BookingListResponse(
        items=[BookingResponse.model_validate(b) for b in items],
        total=total,
        skip=skip,
        limit=limit,
    )


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
    service = BookingService(db)
    all_bookings = await service.booking_repo.get_customer_bookings(current_user.id)

    active_statuses = {
        BookingStatus.PENDING,
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
    }

    active_list = [b for b in all_bookings if b.status in active_statuses]
    results = []
    for b in active_list:
        detailed = await service.booking_repo.get_by_id_with_details(b.id)
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
    service = BookingService(db)
    all_bookings = await service.booking_repo.get_customer_bookings(current_user.id)

    history_statuses = {
        BookingStatus.DELIVERED,
        BookingStatus.COMPLETED,
        BookingStatus.CANCELLED,
        BookingStatus.DELIVERED_ON_WHATSAPP,
    }

    history_list = [b for b in all_bookings if b.status in history_statuses]
    results = []
    for b in history_list:
        detailed = await service.booking_repo.get_by_id_with_details(b.id)
        if detailed:
            results.append(BookingResponse.model_validate(detailed))
    return results


@router.get(
    "/{booking_id}",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Single Booking Details",
)
async def get_booking_detail(
    booking_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    service = BookingService(db)
    booking = await service.booking_repo.get_by_id_with_details(booking_id)

    if not booking:
        raise NotFoundException("Booking not found")

    is_participant = (
        booking.customer_id == current_user.id
        or booking.creator_id == current_user.id
        or current_user.role == UserRole.ADMIN
    )
    if not is_participant:
        raise ForbiddenException("Access to this booking is unauthorized")

    return BookingResponse.model_validate(booking)


@router.post(
    "/{booking_id}/assign",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Assign Creator to Booking",
    description="Assign a videographer to an unassigned or pending booking. Requires Admin or Manager permission.",
)
async def assign_creator_to_booking(
    booking_id: uuid.UUID,
    payload: AssignCreatorRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    service = BookingService(db)
    updated = await service.assign_creator(
        booking_id=booking_id,
        creator_id=payload.creator_id,
        assigned_by=current_user,
        note=payload.note,
    )
    return BookingResponse.model_validate(updated)


@router.post(
    "/{booking_id}/cancel",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel Booking",
    description="Cancel a booking with structured reason. Locked once videographer is on the way.",
)
async def cancel_booking(
    booking_id: uuid.UUID,
    payload: CancelBookingRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    service = BookingService(db)
    updated = await service.cancel_booking(
        booking_id=booking_id,
        cancelled_by=current_user,
        reason=payload.reason,
        note=payload.note,
    )
    return BookingResponse.model_validate(updated)


@router.get(
    "/{booking_id}/timeline",
    response_model=BookingTimelineResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Status Tracking Timeline",
    description="Retrieve chronological status transition history, timestamps, actor labels, and current stage.",
)
async def get_booking_timeline(
    booking_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> BookingTimelineResponse:
    service = BookingService(db)
    return await service.get_booking_timeline(
        booking_id=booking_id,
        requesting_user=current_user,
    )
