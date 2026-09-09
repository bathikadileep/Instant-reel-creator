import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.database import get_db
from app.core.exceptions import ForbiddenException, NotFoundException
from app.models.schema_models import BookingStatus, User, UserRole
from app.repositories.booking_repository import BookingRepository
from app.repositories.creator_repository import CreatorRepository
from app.schemas.booking import BookingResponse
from app.schemas.creator import (
    CreatorDashboardStats,
    DeliverBookingRequest,
    RejectBookingRequest,
    ToggleAvailabilityRequest,
    UpdateBookingStatusRequest,
)

router = APIRouter()


@router.get(
    "/dashboard",
    response_model=CreatorDashboardStats,
    summary="Creator Dashboard Metrics",
    description="Retrieve live dashboard metrics: today's bookings, completed shoots, earnings, and ratings.",
)
async def get_creator_dashboard(
    current_user: User = Depends(deps.require_creator),
    db: AsyncSession = Depends(get_db),
) -> CreatorDashboardStats:
    repo = BookingRepository(db)
    stats_data = await repo.get_creator_dashboard_stats(current_user.id)
    return CreatorDashboardStats(**stats_data)


@router.get(
    "/bookings",
    response_model=List[BookingResponse],
    summary="List Creator Bookings",
    description="Retrieve creator bookings filtered by tab: today, active, completed, available, all.",
)
async def list_creator_bookings(
    tab: str = Query("today", description="Workflow tab: today, active, completed, available, all"),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(deps.require_creator),
    db: AsyncSession = Depends(get_db),
) -> List[BookingResponse]:
    repo = BookingRepository(db)
    bookings = await repo.get_creator_bookings(
        creator_id=current_user.id,
        tab=tab,
        limit=limit,
    )
    return [BookingResponse.model_validate(b) for b in bookings]


@router.get(
    "/bookings/{booking_id}",
    response_model=BookingResponse,
    summary="Get Single Creator Booking",
)
async def get_creator_booking_detail(
    booking_id: uuid.UUID,
    current_user: User = Depends(deps.require_creator),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    repo = BookingRepository(db)
    booking = await repo.get_by_id_with_details(booking_id)
    if not booking:
        raise NotFoundException("Booking not found")

    # Allow creator if assigned, or unassigned pending
    if booking.creator_id is not None and booking.creator_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise ForbiddenException("You are not assigned to this booking")

    return BookingResponse.model_validate(booking)


@router.post(
    "/bookings/{booking_id}/accept",
    response_model=BookingResponse,
    summary="Accept Booking Assignment",
)
async def accept_booking(
    booking_id: uuid.UUID,
    current_user: User = Depends(deps.require_creator),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    repo = BookingRepository(db)
    booking = await repo.get_by_id_with_details(booking_id)
    if not booking:
        raise NotFoundException("Booking not found")

    if booking.creator_id is not None and booking.creator_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Booking is already accepted by another creator",
        )

    updated = await repo.accept_booking(booking_id=booking.id, creator_user_id=current_user.id)
    return BookingResponse.model_validate(updated)


@router.post(
    "/bookings/{booking_id}/reject",
    response_model=BookingResponse,
    summary="Reject Booking Assignment",
)
async def reject_booking(
    booking_id: uuid.UUID,
    request: RejectBookingRequest,
    current_user: User = Depends(deps.require_creator),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    repo = BookingRepository(db)
    booking = await repo.get_by_id_with_details(booking_id)
    if not booking:
        raise NotFoundException("Booking not found")

    if booking.creator_id is not None and booking.creator_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise ForbiddenException("You are not assigned to this booking")

    updated = await repo.reject_booking(
        booking_id=booking.id,
        creator_user_id=current_user.id,
        reason=request.reason,
    )
    return BookingResponse.model_validate(updated)


@router.post(
    "/bookings/{booking_id}/status",
    response_model=BookingResponse,
    summary="Update Booking Status (Workflow Stepper)",
)
async def update_booking_status(
    booking_id: uuid.UUID,
    request: UpdateBookingStatusRequest,
    current_user: User = Depends(deps.require_creator),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    repo = BookingRepository(db)
    booking = await repo.get_by_id_with_details(booking_id)
    if not booking:
        raise NotFoundException("Booking not found")

    if booking.creator_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise ForbiddenException("You can only update bookings assigned to you")

    updated = await repo.update_creator_status(
        booking_id=booking.id,
        creator_user_id=current_user.id,
        new_status=request.status,
        note=request.note,
        reel_url=request.reel_url,
    )
    return BookingResponse.model_validate(updated)


@router.post(
    "/bookings/{booking_id}/deliver",
    response_model=BookingResponse,
    summary="Deliver Reel directly via WhatsApp link",
)
async def deliver_booking(
    booking_id: uuid.UUID,
    request: DeliverBookingRequest,
    current_user: User = Depends(deps.require_creator),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    repo = BookingRepository(db)
    booking = await repo.get_by_id_with_details(booking_id)
    if not booking:
        raise NotFoundException("Booking not found")

    if booking.creator_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise ForbiddenException("You can only deliver bookings assigned to you")

    updated = await repo.update_creator_status(
        booking_id=booking.id,
        creator_user_id=current_user.id,
        new_status=BookingStatus.DELIVERED,
        note=request.note,
        reel_url=request.reel_url,
    )
    return BookingResponse.model_validate(updated)


@router.post(
    "/availability",
    summary="Toggle Creator Availability",
)
async def toggle_availability(
    request: ToggleAvailabilityRequest,
    current_user: User = Depends(deps.require_creator),
    db: AsyncSession = Depends(get_db),
):
    creator_repo = CreatorRepository(db)
    profile = await creator_repo.get_by_user_id(current_user.id)
    if not profile:
        # Create profile if not yet created
        from app.models.schema_models import CreatorProfile
        profile = CreatorProfile(
            user_id=current_user.id,
            primary_city="Khammam",
            whatsapp_number=current_user.mobile,
            is_available=request.is_available,
        )
        db.add(profile)
        await db.commit()
        await db.refresh(profile)
    else:
        profile.is_available = request.is_available
        await db.commit()

    return {"status": "success", "is_available": profile.is_available}
