import logging
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict, List, Optional

from sqlalchemy import and_, func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.exceptions import AppException, ForbiddenException, NotFoundException
from app.models.schema_models import (
    Booking,
    BookingStatus,
    BookingStatusHistory,
    Package,
    Payment,
    PaymentConfig,
    PaymentMethod,
    PaymentStatus,
    User,
    UserRole,
)
from app.schemas.payment import (
    AdminPaymentSummary,
    CashCollectionResponse,
    CreateOrderResponse,
    PaginatedPaymentsResponse,
    PaymentConfigRead,
    PaymentConfigUpdate,
    PaymentListItem,
    PaymentVerificationResponse,
    RefundResponse,
)
from app.services.razorpay_service import razorpay_service

logger = logging.getLogger(__name__)


class PaymentService:
    @staticmethod
    async def get_or_create_config(db: AsyncSession) -> PaymentConfig:
        """Fetch or initialize the global payment configuration."""
        result = await db.execute(
            select(PaymentConfig)
            .where(PaymentConfig.is_deleted == False)
            .order_by(PaymentConfig.created_at.asc())
            .limit(1)
        )
        config = result.scalar_one_or_none()

        if not config:
            config = PaymentConfig(
                cod_enabled=True,
                cod_minimum_advance=Decimal("100.00"),
            )
            db.add(config)
            await db.commit()
            await db.refresh(config)

        return config

    @staticmethod
    async def update_config(
        db: AsyncSession,
        payload: PaymentConfigUpdate,
    ) -> PaymentConfigRead:
        """Update payment and COD settings."""
        config = await PaymentService.get_or_create_config(db)

        if payload.cod_enabled is not None:
            config.cod_enabled = payload.cod_enabled

        if payload.cod_minimum_advance is not None:
            if payload.cod_minimum_advance <= 0:
                raise AppException(
                    message="Minimum COD advance must be greater than zero.",
                    status_code=400,
                    code="INVALID_MINIMUM_ADVANCE",
                )
            config.cod_minimum_advance = Decimal(str(payload.cod_minimum_advance))

        await db.commit()
        await db.refresh(config)

        return PaymentConfigRead(
            id=config.id,
            cod_enabled=config.cod_enabled,
            cod_minimum_advance=float(config.cod_minimum_advance),
            updated_at=config.updated_at,
        )

    @staticmethod
    async def create_order(
        db: AsyncSession,
        booking_id: uuid.UUID,
        payment_method: PaymentMethod,
        current_user: User,
    ) -> CreateOrderResponse:
        """
        Create Razorpay Order for booking.
        Calculates and validates the amount strictly server-side from PostgreSQL package pricing.
        """
        result = await db.execute(
            select(Booking)
            .options(selectinload(Booking.package))
            .where(and_(Booking.id == booking_id, Booking.is_deleted == False))
        )
        booking = result.scalar_one_or_none()
        if not booking:
            raise NotFoundException("Booking not found")

        # Verify access: user is booking owner or admin
        if current_user.role != UserRole.ADMIN and booking.customer_id != current_user.id:
            raise ForbiddenException("You do not have permission to pay for this booking")

        if not booking.package:
            raise AppException(
                message="Booking does not have an associated package.",
                status_code=400,
                code="PACKAGE_NOT_FOUND",
            )

        total_amount = Decimal(str(booking.package.price))
        if total_amount <= 0:
            raise AppException(
                message="Invalid package price.",
                status_code=400,
                code="INVALID_PACKAGE_PRICE",
            )

        # Retrieve COD settings
        config = await PaymentService.get_or_create_config(db)

        if payment_method == PaymentMethod.RAZORPAY_FULL:
            online_charge_amount = total_amount
            advance_amount = total_amount
            remaining_cash_amount = Decimal("0.00")
        elif payment_method == PaymentMethod.COD_WITH_ADVANCE:
            if not config.cod_enabled:
                raise AppException(
                    message="Cash on Delivery is currently disabled by administrator.",
                    status_code=400,
                    code="COD_DISABLED",
                )

            min_advance = config.cod_minimum_advance
            if min_advance <= 0:
                raise AppException(
                    message="Configured COD minimum advance must be greater than zero.",
                    status_code=400,
                    code="INVALID_COD_ADVANCE",
                )

            if min_advance > total_amount:
                raise AppException(
                    message=f"COD minimum advance (Rs. {min_advance}) exceeds total package amount (Rs. {total_amount}).",
                    status_code=400,
                    code="ADVANCE_EXCEEDS_TOTAL",
                )

            online_charge_amount = min_advance
            advance_amount = min_advance
            remaining_cash_amount = total_amount - min_advance
        else:
            raise AppException(
                message="Unsupported payment method.",
                status_code=400,
                code="INVALID_PAYMENT_METHOD",
            )

        # Create Razorpay Order via RazorpayService
        order_dict = razorpay_service.create_order(
            amount=online_charge_amount,
            currency="INR",
            receipt=booking.booking_code,
            notes={
                "booking_id": str(booking.id),
                "booking_code": booking.booking_code,
                "payment_method": payment_method.value,
            },
        )

        razorpay_order_id = order_dict["id"]

        # Update Booking state
        booking.payment_method = payment_method
        booking.total_amount = total_amount
        booking.advance_amount = advance_amount
        booking.remaining_amount = remaining_cash_amount
        booking.payment_status = PaymentStatus.PENDING

        # Create initial PENDING payment record
        payment_record = Payment(
            booking_id=booking.id,
            customer_id=booking.customer_id,
            amount=online_charge_amount,
            currency="INR",
            payment_method=payment_method,
            status=PaymentStatus.PENDING,
            provider="razorpay",
            razorpay_order_id=razorpay_order_id,
        )
        db.add(payment_record)
        await db.commit()
        await db.refresh(payment_record)

        logger.info(
            f"Created payment order: {payment_record.id} | Razorpay Order: {razorpay_order_id} | "
            f"Method: {payment_method.value} | Online Amount: Rs.{online_charge_amount} | "
            f"Total: Rs.{total_amount} | Remaining Cash: Rs.{remaining_cash_amount}"
        )

        return CreateOrderResponse(
            payment_id=payment_record.id,
            booking_id=booking.id,
            booking_code=booking.booking_code,
            razorpay_order_id=razorpay_order_id,
            razorpay_key_id=settings.RAZORPAY_KEY_ID,
            amount=float(online_charge_amount),
            amount_in_paise=int(round(online_charge_amount * 100)),
            currency="INR",
            payment_method=payment_method,
            total_booking_amount=float(total_amount),
            advance_amount=float(advance_amount),
            remaining_cash_amount=float(remaining_cash_amount),
        )

    @staticmethod
    async def verify_payment(
        db: AsyncSession,
        payment_id: uuid.UUID,
        razorpay_order_id: str,
        razorpay_payment_id: str,
        razorpay_signature: str,
        current_user: User,
    ) -> PaymentVerificationResponse:
        """
        Server-side signature verification & atomic database transaction.
        Confirms the booking only upon successful verification.
        """
        # Fetch Payment record with row lock
        res = await db.execute(
            select(Payment)
            .options(selectinload(Payment.booking))
            .where(Payment.id == payment_id)
            .with_for_update()
        )
        payment = res.scalar_one_or_none()
        if not payment:
            raise NotFoundException("Payment record not found")

        booking = payment.booking
        if not booking:
            raise NotFoundException("Associated booking not found")

        # Access check
        if current_user.role != UserRole.ADMIN and payment.customer_id != current_user.id:
            raise ForbiddenException("Access denied to verify this payment")

        # Idempotency check: already paid
        if payment.status in (PaymentStatus.PAID, PaymentStatus.ADVANCE_PAID):
            if payment.razorpay_payment_id == razorpay_payment_id:
                logger.info(f"Idempotent payment verification hit for {payment.id}")
                return PaymentVerificationResponse(
                    success=True,
                    message="Payment already verified successfully.",
                    payment_id=payment.id,
                    booking_id=booking.id,
                    booking_code=booking.booking_code,
                    payment_status=payment.status,
                    booking_status=booking.status.value,
                    total_amount=float(booking.total_amount or payment.amount),
                    advance_amount=float(booking.advance_amount),
                    remaining_amount=float(booking.remaining_amount),
                )
            else:
                raise AppException(
                    message="Payment has already been processed with a different payment ID.",
                    status_code=400,
                    code="PAYMENT_ALREADY_PROCESSED",
                )

        # Duplicate payment_id check across other payments
        dup_check = await db.execute(
            select(Payment).where(
                and_(
                    Payment.razorpay_payment_id == razorpay_payment_id,
                    Payment.id != payment.id,
                )
            )
        )
        if dup_check.scalar_one_or_none():
            raise AppException(
                message="Duplicate Razorpay payment ID detected.",
                status_code=400,
                code="DUPLICATE_PAYMENT_ID",
            )

        # Verify Razorpay order ID matches stored order
        if payment.razorpay_order_id and payment.razorpay_order_id != razorpay_order_id:
            raise AppException(
                message="Razorpay Order ID mismatch.",
                status_code=400,
                code="ORDER_ID_MISMATCH",
            )

        # Cryptographic Signature Verification
        is_valid_sig = razorpay_service.verify_payment_signature(
            order_id=razorpay_order_id,
            payment_id=razorpay_payment_id,
            signature=razorpay_signature,
        )

        if not is_valid_sig:
            payment.status = PaymentStatus.FAILED
            payment.failure_reason = "Cryptographic signature verification failed"
            await db.commit()
            raise AppException(
                message="Razorpay payment signature verification failed. Transaction rejected.",
                status_code=400,
                code="INVALID_SIGNATURE",
            )

        # Update Payment Record
        now = datetime.now(timezone.utc)
        payment.razorpay_payment_id = razorpay_payment_id
        payment.razorpay_signature = razorpay_signature
        payment.transaction_id = razorpay_payment_id
        payment.paid_at = now

        # Update Booking and Payment Status based on method
        if payment.payment_method == PaymentMethod.COD_WITH_ADVANCE:
            payment.status = PaymentStatus.ADVANCE_PAID
            booking.payment_status = PaymentStatus.ADVANCE_PAID
            status_note = f"COD Advance of Rs.{payment.amount:,.2f} verified. Cash to collect on-site: Rs.{booking.remaining_amount:,.2f}"
        else:
            payment.status = PaymentStatus.PAID
            booking.payment_status = PaymentStatus.PAID
            booking.remaining_amount = Decimal("0.00")
            booking.advance_amount = booking.total_amount or payment.amount
            status_note = f"Full Online Payment of Rs.{payment.amount:,.2f} verified via Razorpay."

        # Booking is now confirmed
        booking.status = BookingStatus.PENDING  # Confirmed pending creator acceptance/assignment

        # Add immutable audit trail entry
        history_entry = BookingStatusHistory(
            booking_id=booking.id,
            status=BookingStatus.PENDING,
            note=status_note,
            changed_by_user_id=current_user.id,
        )
        db.add(history_entry)

        await db.commit()
        await db.refresh(payment)
        await db.refresh(booking)

        logger.info(
            f"Payment verified: {payment.id} | Booking {booking.booking_code} CONFIRMED | "
            f"Status: {payment.status.value} | Advance: Rs.{booking.advance_amount} | "
            f"Remaining: Rs.{booking.remaining_amount}"
        )

        return PaymentVerificationResponse(
            success=True,
            message="Payment successfully verified and booking confirmed.",
            payment_id=payment.id,
            booking_id=booking.id,
            booking_code=booking.booking_code,
            payment_status=payment.status,
            booking_status=booking.status.value,
            total_amount=float(booking.total_amount or payment.amount),
            advance_amount=float(booking.advance_amount),
            remaining_amount=float(booking.remaining_amount),
        )

    @staticmethod
    async def collect_cash(
        db: AsyncSession,
        booking_id: uuid.UUID,
        creator: User,
    ) -> CashCollectionResponse:
        """
        Assigned creator collects outstanding cash for COD booking on-site.
        Atomically records cash collection and prevents double collection.
        """
        # Lock booking row for atomic idempotency
        res = await db.execute(
            select(Booking)
            .where(and_(Booking.id == booking_id, Booking.is_deleted == False))
            .with_for_update()
        )
        booking = res.scalar_one_or_none()
        if not booking:
            raise NotFoundException("Booking not found")

        # 1. Creator authorization checks
        if creator.role not in (UserRole.CREATOR, UserRole.ADMIN):
            raise ForbiddenException("Only assigned creators can record cash collection")

        if creator.role == UserRole.CREATOR and booking.creator_id != creator.id:
            raise ForbiddenException("You are not the assigned videographer for this booking")

        # 2. Check booking state
        if booking.status == BookingStatus.CANCELLED:
            raise AppException(
                message="Cannot collect cash for a cancelled booking.",
                status_code=400,
                code="BOOKING_CANCELLED",
            )

        if booking.payment_method != PaymentMethod.COD_WITH_ADVANCE:
            raise AppException(
                message="This booking was not configured for Cash on Delivery.",
                status_code=400,
                code="NOT_COD_BOOKING",
            )

        # 3. Double cash collection prevention / Idempotency
        if booking.cash_collected:
            logger.info(f"Idempotent cash collection triggered for booking {booking.booking_code}")
            return CashCollectionResponse(
                success=True,
                message="Cash payment has already been recorded.",
                booking_id=booking.id,
                booking_code=booking.booking_code,
                cash_collected=True,
                cash_collected_at=booking.cash_collected_at or datetime.now(timezone.utc),
                remaining_amount=0.0,
                payment_status=booking.payment_status,
            )

        cash_amount = booking.remaining_amount
        if cash_amount <= 0:
            raise AppException(
                message="No outstanding cash balance to collect.",
                status_code=400,
                code="ZERO_REMAINING_BALANCE",
            )

        now = datetime.now(timezone.utc)
        booking.cash_collected = True
        booking.cash_collected_at = now
        booking.remaining_amount = Decimal("0.00")
        booking.payment_status = PaymentStatus.PAID

        # Create cash payment record for audit
        cash_tx_id = f"CASH-{booking.booking_code}-{uuid.uuid4().hex[:6].upper()}"
        cash_payment = Payment(
            booking_id=booking.id,
            customer_id=booking.customer_id,
            amount=cash_amount,
            currency="INR",
            payment_method=PaymentMethod.COD_WITH_ADVANCE,
            status=PaymentStatus.PAID,
            provider="cash_on_delivery",
            transaction_id=cash_tx_id,
            paid_at=now,
        )
        db.add(cash_payment)

        # Status history entry
        history_entry = BookingStatusHistory(
            booking_id=booking.id,
            status=booking.status,
            note=f"Collected Rs.{cash_amount:,.2f} in cash from client by videographer {creator.name or creator.mobile}.",
            changed_by_user_id=creator.id,
        )
        db.add(history_entry)

        await db.commit()
        await db.refresh(booking)

        logger.info(
            f"Cash collected for booking {booking.booking_code}: Rs.{cash_amount} by {creator.name}"
        )

        return CashCollectionResponse(
            success=True,
            message=f"Cash payment of Rs. {cash_amount:,.2f} successfully recorded.",
            booking_id=booking.id,
            booking_code=booking.booking_code,
            cash_collected=True,
            cash_collected_at=now,
            remaining_amount=0.0,
            payment_status=PaymentStatus.PAID,
        )

    @staticmethod
    async def process_refund(
        db: AsyncSession,
        payment_id: uuid.UUID,
        reason: Optional[str],
        admin_user: User,
    ) -> RefundResponse:
        """Admin processes an online refund via Razorpay."""
        if admin_user.role != UserRole.ADMIN:
            raise ForbiddenException("Only administrators can initiate refunds")

        res = await db.execute(
            select(Payment)
            .options(selectinload(Payment.booking))
            .where(Payment.id == payment_id)
            .with_for_update()
        )
        payment = res.scalar_one_or_none()
        if not payment:
            raise NotFoundException("Payment not found")

        if payment.status not in (PaymentStatus.PAID, PaymentStatus.ADVANCE_PAID):
            raise AppException(
                message=f"Cannot refund payment with status '{payment.status.value}'.",
                status_code=400,
                code="INVALID_REFUND_STATUS",
            )

        if payment.provider == "cash_on_delivery":
            raise AppException(
                message="Cannot refund cash payments through Razorpay gateway.",
                status_code=400,
                code="CANNOT_REFUND_CASH_ONLINE",
            )

        # Process refund with Razorpay
        refund_dict = razorpay_service.process_refund(
            payment_id=payment.razorpay_payment_id or str(payment.id),
            amount=payment.amount,
            notes={"refund_reason": reason or "Admin initiated refund"},
        )

        payment.status = PaymentStatus.REFUNDED
        payment.failure_reason = f"Refunded: {reason or 'Admin initiated'}"

        if payment.booking:
            payment.booking.payment_status = PaymentStatus.REFUNDED

        await db.commit()
        await db.refresh(payment)

        return RefundResponse(
            success=True,
            message="Refund processed successfully.",
            payment_id=payment.id,
            refund_id=refund_dict.get("id"),
            amount_refunded=float(payment.amount),
            status=PaymentStatus.REFUNDED,
        )

    @staticmethod
    async def get_admin_payments(
        db: AsyncSession,
        payment_method: Optional[str] = None,
        payment_status: Optional[str] = None,
        cash_collected: Optional[bool] = None,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> PaginatedPaymentsResponse:
        """Fetch all payments with filtering for the Admin Console."""
        query = (
            select(Payment)
            .join(Booking, Payment.booking_id == Booking.id)
            .options(
                selectinload(Payment.booking).selectinload(Booking.customer),
                selectinload(Payment.booking).selectinload(Booking.creator),
                selectinload(Payment.booking).selectinload(Booking.package),
            )
            .where(Payment.is_deleted == False)
            .order_by(Payment.created_at.desc())
        )

        if payment_method and payment_method != "all":
            query = query.where(Payment.payment_method == payment_method)

        if payment_status and payment_status != "all":
            query = query.where(Payment.status == payment_status)

        if cash_collected is not None:
            query = query.where(Booking.cash_collected == cash_collected)

        if search and search.strip():
            s = f"%{search.strip()}%"
            query = query.where(
                or_(
                    Booking.booking_code.ilike(s),
                    Payment.razorpay_order_id.ilike(s),
                    Payment.razorpay_payment_id.ilike(s),
                )
            )

        # Count total
        count_query = select(func.count()).select_from(query.subquery())
        total = await db.scalar(count_query) or 0

        # Paginate
        offset = (page - 1) * page_size
        paginated_query = query.offset(offset).limit(page_size)
        res = await db.execute(paginated_query)
        payments = res.scalars().all()

        items = []
        for p in payments:
            b = p.booking
            cust = b.customer if b else None
            creator = b.creator if b else None
            pkg = b.package if b else None

            items.append(
                PaymentListItem(
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
            )

        total_pages = (total + page_size - 1) // page_size if total > 0 else 1

        return PaginatedPaymentsResponse(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages,
        )

    @staticmethod
    async def get_payment_summary(db: AsyncSession) -> AdminPaymentSummary:
        """Aggregate payment analytics for the Admin Panel."""
        # Total Revenue (All Paid & Advance Paid)
        total_rev = await db.scalar(
            select(func.coalesce(func.sum(Payment.amount), 0)).where(
                and_(
                    Payment.is_deleted == False,
                    Payment.status.in_([PaymentStatus.PAID, PaymentStatus.ADVANCE_PAID]),
                )
            )
        ) or Decimal("0.00")

        # Online Revenue (Provider = razorpay)
        online_rev = await db.scalar(
            select(func.coalesce(func.sum(Payment.amount), 0)).where(
                and_(
                    Payment.is_deleted == False,
                    Payment.provider == "razorpay",
                    Payment.status.in_([PaymentStatus.PAID, PaymentStatus.ADVANCE_PAID]),
                )
            )
        ) or Decimal("0.00")

        # COD Advance Revenue
        cod_advance = await db.scalar(
            select(func.coalesce(func.sum(Payment.amount), 0)).where(
                and_(
                    Payment.is_deleted == False,
                    Payment.payment_method == PaymentMethod.COD_WITH_ADVANCE,
                    Payment.provider == "razorpay",
                    Payment.status.in_([PaymentStatus.PAID, PaymentStatus.ADVANCE_PAID]),
                )
            )
        ) or Decimal("0.00")

        # Cash Collected
        cash_coll = await db.scalar(
            select(func.coalesce(func.sum(Payment.amount), 0)).where(
                and_(
                    Payment.is_deleted == False,
                    Payment.provider == "cash_on_delivery",
                    Payment.status == PaymentStatus.PAID,
                )
            )
        ) or Decimal("0.00")

        # COD Outstanding
        cod_out = await db.scalar(
            select(func.coalesce(func.sum(Booking.remaining_amount), 0)).where(
                and_(
                    Booking.is_deleted == False,
                    Booking.payment_method == PaymentMethod.COD_WITH_ADVANCE,
                    Booking.cash_collected == False,
                    Booking.status != BookingStatus.CANCELLED,
                )
            )
        ) or Decimal("0.00")

        succ_count = await db.scalar(
            select(func.count(Payment.id)).where(
                and_(
                    Payment.is_deleted == False,
                    Payment.status.in_([PaymentStatus.PAID, PaymentStatus.ADVANCE_PAID]),
                )
            )
        ) or 0

        fail_count = await db.scalar(
            select(func.count(Payment.id)).where(
                and_(Payment.is_deleted == False, Payment.status == PaymentStatus.FAILED)
            )
        ) or 0

        ref_count = await db.scalar(
            select(func.count(Payment.id)).where(
                and_(Payment.is_deleted == False, Payment.status == PaymentStatus.REFUNDED)
            )
        ) or 0

        return AdminPaymentSummary(
            total_revenue=float(total_rev),
            online_revenue=float(online_rev),
            cod_advance_revenue=float(cod_advance),
            cash_collected=float(cash_coll),
            cod_outstanding=float(cod_out),
            successful_payments=succ_count,
            failed_payments=fail_count,
            refunded_payments=ref_count,
        )
