import logging
import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_active_user, get_db, require_admin, require_creator
from app.core.exceptions import AppException, NotFoundException
from app.models.schema_models import Booking, Payment, User
from app.schemas.payment import (
    AdminPaymentSummary,
    CashCollectionResponse,
    CollectCashRequest,
    CreateOrderRequest,
    CreateOrderResponse,
    PaginatedPaymentsResponse,
    PaymentConfigRead,
    PaymentConfigUpdate,
    PaymentListItem,
    PaymentVerificationResponse,
    RefundRequest,
    RefundResponse,
    VerifyPaymentRequest,
)
from app.services.payment_service import PaymentService
from app.services.razorpay_service import razorpay_service

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get(
    "/config",
    response_model=PaymentConfigRead,
    status_code=status.HTTP_200_OK,
    summary="Get Payment & COD Configuration",
    description="Returns current Cash on Delivery availability and minimum advance amount (e.g. ₹100).",
)
async def get_payment_config(
    db: AsyncSession = Depends(get_db),
) -> PaymentConfigRead:
    config = await PaymentService.get_or_create_config(db)
    return PaymentConfigRead(
        id=config.id,
        cod_enabled=config.cod_enabled,
        cod_minimum_advance=float(config.cod_minimum_advance),
        updated_at=config.updated_at,
    )


@router.put(
    "/config",
    response_model=PaymentConfigRead,
    status_code=status.HTTP_200_OK,
    summary="Update Payment & COD Configuration (Admin Only)",
    description="Allows administrators to toggle Cash on Delivery and change the required minimum advance.",
)
async def update_payment_config(
    payload: PaymentConfigUpdate,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> PaymentConfigRead:
    return await PaymentService.update_config(db=db, payload=payload)


@router.post(
    "/create-order",
    response_model=CreateOrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Razorpay Order for Full or COD Advance Payment",
    description="Calculates exact price from database package, creates Razorpay Order, and returns public order parameters.",
)
async def create_payment_order(
    payload: CreateOrderRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> CreateOrderResponse:
    return await PaymentService.create_order(
        db=db,
        booking_id=payload.booking_id,
        payment_method=payload.payment_method,
        current_user=current_user,
    )


@router.post(
    "/verify",
    response_model=PaymentVerificationResponse,
    status_code=status.HTTP_200_OK,
    summary="Verify Razorpay Payment Signature Server-Side",
    description="Cryptographically verifies payment HMAC-SHA256 signature and confirms booking in a transactional block.",
)
async def verify_payment(
    payload: VerifyPaymentRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> PaymentVerificationResponse:
    return await PaymentService.verify_payment(
        db=db,
        payment_id=payload.payment_id,
        razorpay_order_id=payload.razorpay_order_id,
        razorpay_payment_id=payload.razorpay_payment_id,
        razorpay_signature=payload.razorpay_signature,
        current_user=current_user,
    )


@router.post(
    "/collect-cash",
    response_model=CashCollectionResponse,
    status_code=status.HTTP_200_OK,
    summary="Record COD Cash Collection by Assigned Creator",
    description="Assigned videographer records on-site cash collection. Prevents double-collection via row-locking.",
)
async def collect_cash(
    payload: CollectCashRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> CashCollectionResponse:
    return await PaymentService.collect_cash(
        db=db,
        booking_id=payload.booking_id,
        creator=current_user,
    )


@router.post(
    "/webhook",
    status_code=status.HTTP_200_OK,
    summary="Razorpay Webhook Endpoint",
    description="Receives asynchronous payment and refund notifications from Razorpay.",
)
async def razorpay_webhook(
    request: Request,
    x_razorpay_signature: Optional[str] = Header(None, alias="X-Razorpay-Signature"),
    db: AsyncSession = Depends(get_db),
):
    body = await request.body()
    if not x_razorpay_signature:
        raise HTTPException(status_code=400, detail="Missing Razorpay signature header")

    is_valid = razorpay_service.verify_webhook_signature(body, x_razorpay_signature)
    if not is_valid:
        raise HTTPException(status_code=400, detail="Invalid Razorpay webhook signature")

    payload = await request.json()
    event = payload.get("event")
    logger.info(f"Received verified Razorpay webhook event: {event}")
    return {"status": "success", "event": event}


@router.post(
    "/{payment_id}/refund",
    response_model=RefundResponse,
    status_code=status.HTTP_200_OK,
    summary="Process Refund via Razorpay (Admin Only)",
    description="Initiates an online refund for online payments.",
)
async def process_refund(
    payment_id: uuid.UUID,
    payload: RefundRequest,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> RefundResponse:
    return await PaymentService.process_refund(
        db=db,
        payment_id=payment_id,
        reason=payload.reason,
        admin_user=current_user,
    )


@router.get(
    "/booking/{booking_id}",
    response_model=Optional[PaymentListItem],
    status_code=status.HTTP_200_OK,
    summary="Get Payment Information for Booking",
)
async def get_booking_payment(
    booking_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> Optional[PaymentListItem]:
    res = await db.execute(
        select(Payment)
        .options(
            selectinload(Payment.booking).selectinload(Booking.customer),
            selectinload(Payment.booking).selectinload(Booking.creator),
            selectinload(Payment.booking).selectinload(Booking.package),
        )
        .where(Payment.booking_id == booking_id)
        .order_by(Payment.created_at.desc())
        .limit(1)
    )
    p = res.scalar_one_or_none()
    if not p:
        return None

    b = p.booking
    cust = b.customer if b else None
    creator = b.creator if b else None
    pkg = b.package if b else None

    return PaymentListItem(
        id=p.id,
        booking_id=p.booking_id,
        booking_code=b.booking_code if b else "N/A",
        customer_id=p.customer_id,
        customer_name=cust.name if cust else "Customer",
        customer_mobile=cust.mobile if cust else "",
        creator_name=creator.name if creator else None,
        city=b.city if b else "",
        package_name=pkg.name if pkg else "Standard",
        amount=float(p.amount),
        currency=p.currency,
        payment_method=p.payment_method.value if p.payment_method else None,
        payment_status=p.status,
        razorpay_order_id=p.razorpay_order_id,
        razorpay_payment_id=p.razorpay_payment_id,
        total_amount=float(b.total_amount or p.amount) if b else float(p.amount),
        advance_amount=float(b.advance_amount) if b else 0.0,
        remaining_amount=float(b.remaining_amount) if b else 0.0,
        cash_collected=b.cash_collected if b else False,
        cash_collected_at=b.cash_collected_at if b else None,
        created_at=p.created_at,
        updated_at=p.updated_at,
    )


@router.get(
    "/admin/all",
    response_model=PaginatedPaymentsResponse,
    status_code=status.HTTP_200_OK,
    summary="List All Payments with Filters (Admin Only)",
)
async def list_admin_payments(
    payment_method: Optional[str] = Query(None, description="Filter: razorpay_full or cod_with_advance"),
    payment_status: Optional[str] = Query(None, description="Filter: pending, advance_paid, paid, failed, refunded"),
    cash_collected: Optional[bool] = Query(None, description="Filter by COD cash collection state"),
    search: Optional[str] = Query(None, description="Search booking code or razorpay id"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> PaginatedPaymentsResponse:
    return await PaymentService.get_admin_payments(
        db=db,
        payment_method=payment_method,
        payment_status=payment_status,
        cash_collected=cash_collected,
        search=search,
        page=page,
        page_size=page_size,
    )


@router.get(
    "/admin/summary",
    response_model=AdminPaymentSummary,
    status_code=status.HTTP_200_OK,
    summary="Get Payment & Revenue Summary (Admin Only)",
)
async def get_payment_summary(
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> AdminPaymentSummary:
    return await PaymentService.get_payment_summary(db=db)
