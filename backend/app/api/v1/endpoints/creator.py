import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.database import get_db
from app.core.exceptions import ForbiddenException, NotFoundException
from app.models.schema_models import BookingStatus, User, UserRole
import re
from datetime import datetime, timezone
from urllib.parse import quote_plus
from app.repositories.booking_repository import BookingRepository
from app.repositories.creator_repository import CreatorRepository
from app.schemas.booking import BookingResponse
from app.schemas.creator import (
    CreatorDashboardStats,
    DeliverBookingRequest,
    MarkDeliveredRequest,
    RejectBookingRequest,
    SendReelResponse,
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

    # Dispatch Customer: Creator Assigned push notification
    from app.services.fcm_service import FCMService
    await FCMService.notify_creator_assigned(
        db=db,
        booking=updated,
        creator_name=current_user.name or "Your Videographer",
    )

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

    # Dispatch Customer: Creator Reached alert if videographer arrived on location
    if request.status in (BookingStatus.ARRIVED_AT_LOCATION, BookingStatus.REACHED):
        from app.services.fcm_service import FCMService
        await FCMService.notify_creator_reached(
            db=db,
            booking=updated,
            creator_name=current_user.name or "Your Videographer",
        )

    return BookingResponse.model_validate(updated)


@router.post(
    "/bookings/{booking_id}/send-reel",
    response_model=SendReelResponse,
    summary="Initiate WhatsApp Reel Transfer",
    description="Updates delivery_status to 'shared_on_whatsapp' and returns deep-link URL to open customer WhatsApp chat directly.",
)
async def send_reel_whatsapp(
    booking_id: uuid.UUID,
    current_user: User = Depends(deps.require_creator),
    db: AsyncSession = Depends(get_db),
) -> SendReelResponse:
    repo = BookingRepository(db)
    booking = await repo.get_by_id_with_details(booking_id)
    if not booking:
        raise NotFoundException("Booking not found")

    if booking.creator_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise ForbiddenException("You can only deliver bookings assigned to you")

    # Clean and format phone number for WhatsApp wa.me link
    raw_phone = booking.customer_whatsapp or ""
    clean_digits = re.sub(r"[^0-9]", "", raw_phone)
    if len(clean_digits) == 10:
        clean_phone = f"91{clean_digits}"
    elif clean_digits.startswith("91") and len(clean_digits) == 12:
        clean_phone = clean_digits
    else:
        clean_phone = clean_digits

    customer_name = booking.customer.name if booking.customer and booking.customer.name else "Valued Client"
    creator_name = current_user.name or "Instant Reel Videographer"

    message = (
        f"Hi {customer_name}! Your Instant Reel for booking {booking.booking_code} "
        f"has been shot & edited on-site by {creator_name}. "
        f"Here is your 4K video reel!"
    )
    whatsapp_url = f"https://wa.me/{clean_phone}?text={quote_plus(message)}"

    # Update delivery tracking status
    booking.delivery_status = "shared_on_whatsapp"

    from app.models.schema_models import BookingStatusHistory
    history = BookingStatusHistory(
        booking_id=booking.id,
        status=booking.status,
        note=f"Videographer initiated reel delivery via WhatsApp to {booking.customer_whatsapp}",
        changed_by_user_id=current_user.id,
    )
    db.add(history)
    await db.commit()
    await db.refresh(booking)

    return SendReelResponse(
        booking_id=booking.id,
        booking_code=booking.booking_code,
        customer_name=customer_name,
        customer_whatsapp=booking.customer_whatsapp,
        whatsapp_url=whatsapp_url,
        prefilled_message=message,
        delivery_status=booking.delivery_status,
    )


@router.post(
    "/bookings/{booking_id}/mark-delivered",
    response_model=BookingResponse,
    summary="Mark Booking Delivered after WhatsApp Sharing",
    description="Confirms reel was sent via WhatsApp. Updates delivery_status='delivered', records delivered_at timestamp, and marks booking status DELIVERED.",
)
async def mark_booking_delivered(
    booking_id: uuid.UUID,
    request: Optional[MarkDeliveredRequest] = None,
    current_user: User = Depends(deps.require_creator),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    repo = BookingRepository(db)
    creator_repo = CreatorRepository(db)

    booking = await repo.get_by_id_with_details(booking_id)
    if not booking:
        raise NotFoundException("Booking not found")

    if booking.creator_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise ForbiddenException("You can only deliver bookings assigned to you")

    now = datetime.now(timezone.utc)
    booking.status = BookingStatus.DELIVERED
    booking.delivery_status = "delivered"
    booking.delivered_at = now

    note_text = request.note if request and request.note else "Reel delivered directly to customer via WhatsApp."

    from app.models.schema_models import BookingStatusHistory
    history = BookingStatusHistory(
        booking_id=booking.id,
        status=BookingStatus.DELIVERED,
        note=note_text,
        changed_by_user_id=current_user.id,
    )
    db.add(history)

    # Increment creator delivery statistics
    await creator_repo.increment_reels_delivered(current_user.id)

    await db.commit()
    refreshed = await repo.get_by_id_with_details(booking.id)

    # Dispatch Customer: Reel Delivered push notification
    from app.services.fcm_service import FCMService
    await FCMService.notify_reel_delivered(db=db, booking=refreshed)

    return BookingResponse.model_validate(refreshed)


@router.post(
    "/bookings/{booking_id}/deliver",
    response_model=BookingResponse,
    summary="Deliver Reel (Backwards Compatible Endpoint)",
)
async def deliver_booking(
    booking_id: uuid.UUID,
    request: DeliverBookingRequest,
    current_user: User = Depends(deps.require_creator),
    db: AsyncSession = Depends(get_db),
) -> BookingResponse:
    repo = BookingRepository(db)
    creator_repo = CreatorRepository(db)

    booking = await repo.get_by_id_with_details(booking_id)
    if not booking:
        raise NotFoundException("Booking not found")

    if booking.creator_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise ForbiddenException("You can only deliver bookings assigned to you")

    now = datetime.now(timezone.utc)
    booking.status = BookingStatus.DELIVERED
    booking.delivery_status = "delivered"
    booking.delivered_at = now
    if request.reel_url:
        booking.reel_url = request.reel_url

    from app.models.schema_models import BookingStatusHistory
    history = BookingStatusHistory(
        booking_id=booking.id,
        status=BookingStatus.DELIVERED,
        note=request.note or "Reel delivered directly to customer via WhatsApp",
        changed_by_user_id=current_user.id,
    )
    db.add(history)

    await creator_repo.increment_reels_delivered(current_user.id)
    await db.commit()
    refreshed = await repo.get_by_id_with_details(booking.id)

    # Dispatch Customer: Reel Delivered push notification
    from app.services.fcm_service import FCMService
    await FCMService.notify_reel_delivered(db=db, booking=refreshed)

    return BookingResponse.model_validate(refreshed)


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
