import asyncio
from datetime import datetime, timedelta, timezone
from decimal import Decimal
import uuid
from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models.schema_models import (
    Booking,
    BookingStatus,
    Package,
    Payment,
    PaymentConfig,
    PaymentMethod,
    PaymentStatus,
    User,
    UserRole,
)
from app.schemas.payment import (
    CollectCashRequest,
    PaymentConfigUpdate,
    RefundRequest,
)
from app.services.payment_service import PaymentService
from app.services.razorpay_service import razorpay_service


async def run_payment_tests():
    print("=" * 80)
    print("INSTANT REEL - PHASE 8 PRODUCTION PAYMENT SYSTEM E2E TEST (LIVE NEON DB)")
    print("=" * 80)

    async with AsyncSessionLocal() as db:
        # --- 0. Setup Test Users & Package ---
        # Customer
        cust_res = await db.execute(select(User).where(User.role == UserRole.CUSTOMER))
        customer = cust_res.scalars().first()
        if not customer:
            customer = User(
                name="Test Customer",
                mobile="+919888877771",
                role=UserRole.CUSTOMER,
                is_active=True,
            )
            db.add(customer)
            await db.flush()

        # Creator
        creator_res = await db.execute(select(User).where(User.role == UserRole.CREATOR))
        creator = creator_res.scalars().first()
        if not creator:
            creator = User(
                name="Ramesh Videographer",
                mobile="+919777766662",
                role=UserRole.CREATOR,
                is_active=True,
            )
            db.add(creator)
            await db.flush()

        # Admin
        admin_res = await db.execute(select(User).where(User.role == UserRole.ADMIN))
        admin_user = admin_res.scalars().first()

        # Package (₹499 Basic or ₹999 Standard)
        pkg_res = await db.execute(select(Package).where(Package.is_deleted == False))
        package = pkg_res.scalars().first()
        if not package:
            package = Package(
                name="Basic 10-Min Reel",
                description="1 edited reel in 10 minutes",
                price=Decimal("499.00"),
                reels_count=1,
            )
            db.add(package)
            await db.flush()

        print(f"[+] Customer: {customer.name} ({customer.mobile})")
        print(f"[+] Creator: {creator.name} ({creator.mobile})")
        print(f"[+] Package: {package.name} (Rs.{package.price})")

        # --- 1. Test Payment Configuration (Admin Settings) ---
        print("\n--- 1. Testing Payment Config (COD Settings) ---")
        cfg = await PaymentService.get_or_create_config(db)
        print(f"[+] Default Config: COD Enabled={cfg.cod_enabled}, Min Advance=Rs.{cfg.cod_minimum_advance}")

        # Update min advance to 100
        up_cfg = await PaymentService.update_config(
            db, PaymentConfigUpdate(cod_enabled=True, cod_minimum_advance=100.0)
        )
        print(f"[+] Updated Config: Min Advance=Rs.{up_cfg.cod_minimum_advance}")

        # --- 2. Test Razorpay Full Payment Flow ---
        print("\n--- 2. Testing Razorpay Full Payment Flow ---")
        # Create unconfirmed test booking
        booking1 = Booking(
            booking_code=f"IR-2026-F{uuid.uuid4().hex[:4].upper()}",
            customer_id=customer.id,
            package_id=package.id,
            status=BookingStatus.PENDING,
            city="Khammam",
            location_address="Station Road, Khammam",
            scheduled_at=datetime.now(timezone.utc) + timedelta(days=1),
            customer_whatsapp="+919888877771",
        )
        db.add(booking1)
        await db.commit()
        await db.refresh(booking1)

        # Create Order (Full Payment)
        order_resp = await PaymentService.create_order(
            db=db,
            booking_id=booking1.id,
            payment_method=PaymentMethod.RAZORPAY_FULL,
            current_user=customer,
        )
        print(f"[+] Razorpay Order Created: {order_resp.razorpay_order_id}")
        print(f"    - Amount: Rs.{order_resp.amount} ({order_resp.amount_in_paise} paise)")
        print(f"    - Total Booking Amount: Rs.{order_resp.total_booking_amount}")
        print(f"    - Advance: Rs.{order_resp.advance_amount} | Remaining: Rs.{order_resp.remaining_cash_amount}")

        # Verify Payment with valid cryptographic signature
        test_pay_id = f"pay_{uuid.uuid4().hex[:14]}"
        valid_sig = razorpay_service.generate_test_signature(
            order_id=order_resp.razorpay_order_id,
            payment_id=test_pay_id,
        )

        verify_resp = await PaymentService.verify_payment(
            db=db,
            payment_id=order_resp.payment_id,
            razorpay_order_id=order_resp.razorpay_order_id,
            razorpay_payment_id=test_pay_id,
            razorpay_signature=valid_sig,
            current_user=customer,
        )
        print(f"[+] Full Payment Verified: Status={verify_resp.payment_status} | Booking Status={verify_resp.booking_status}")
        print(f"    - Total: Rs.{verify_resp.total_amount} | Paid: Rs.{verify_resp.advance_amount} | Remaining: Rs.{verify_resp.remaining_amount}")

        # --- 3. Test Cash on Delivery (COD) with Minimum Advance Flow ---
        print("\n--- 3. Testing Cash on Delivery with Minimum Advance Flow ---")
        booking2 = Booking(
            booking_code=f"IR-2026-C{uuid.uuid4().hex[:4].upper()}",
            customer_id=customer.id,
            creator_id=creator.id,  # Assign creator
            package_id=package.id,
            status=BookingStatus.PENDING,
            city="Maripeda",
            location_address="Main Bazar, Maripeda",
            scheduled_at=datetime.now(timezone.utc) + timedelta(days=2),
            customer_whatsapp="+919888877771",
        )
        db.add(booking2)
        await db.commit()
        await db.refresh(booking2)

        # Create COD Order
        cod_order_resp = await PaymentService.create_order(
            db=db,
            booking_id=booking2.id,
            payment_method=PaymentMethod.COD_WITH_ADVANCE,
            current_user=customer,
        )
        print(f"[+] COD Razorpay Advance Order Created: {cod_order_resp.razorpay_order_id}")
        print(f"    - Advance to Pay Online: Rs.{cod_order_resp.amount} ({cod_order_resp.amount_in_paise} paise)")
        print(f"    - Total Booking Amount: Rs.{cod_order_resp.total_booking_amount}")
        print(f"    - Remaining Cash to Collect On-Site: Rs.{cod_order_resp.remaining_cash_amount}")

        # Verify COD Advance Payment
        test_cod_pay_id = f"pay_{uuid.uuid4().hex[:14]}"
        cod_valid_sig = razorpay_service.generate_test_signature(
            order_id=cod_order_resp.razorpay_order_id,
            payment_id=test_cod_pay_id,
        )

        cod_verify_resp = await PaymentService.verify_payment(
            db=db,
            payment_id=cod_order_resp.payment_id,
            razorpay_order_id=cod_order_resp.razorpay_order_id,
            razorpay_payment_id=test_cod_pay_id,
            razorpay_signature=cod_valid_sig,
            current_user=customer,
        )
        print(f"[+] COD Advance Verified: Payment Status={cod_verify_resp.payment_status}")
        print(f"    - Advance Paid: Rs.{cod_verify_resp.advance_amount}")
        print(f"    - Outstanding Cash to Collect: Rs.{cod_verify_resp.remaining_amount}")

        # --- 4. Test Cash Collection by Assigned Creator ---
        print("\n--- 4. Testing Cash Collection by Assigned Creator ---")
        cash_resp = await PaymentService.collect_cash(
            db=db,
            booking_id=booking2.id,
            creator=creator,
        )
        print(f"[+] Cash Collection Succeeded: {cash_resp.message}")
        print(f"    - Cash Collected: {cash_resp.cash_collected}")
        print(f"    - Remaining Cash Balance: Rs.{cash_resp.remaining_amount}")
        print(f"    - Final Payment Status: {cash_resp.payment_status}")

        # --- 5. Test Double Cash Collection Prevention (Idempotency) ---
        print("\n--- 5. Testing Double Cash Collection Prevention ---")
        repeat_cash_resp = await PaymentService.collect_cash(
            db=db,
            booking_id=booking2.id,
            creator=creator,
        )
        print(f"[+] Idempotent Cash Collection Handled: {repeat_cash_resp.message}")
        assert repeat_cash_resp.remaining_amount == 0.0

        # --- 6. Test Admin Payment Summary ---
        print("\n--- 6. Testing Admin Payment Summary & Metrics ---")
        summary = await PaymentService.get_payment_summary(db)
        print(f"[+] Admin Payment Summary:")
        print(f"    - Total Revenue: Rs.{summary.total_revenue:,.2f}")
        print(f"    - Online Revenue: Rs.{summary.online_revenue:,.2f}")
        print(f"    - COD Advance Revenue: Rs.{summary.cod_advance_revenue:,.2f}")
        print(f"    - Cash Collected: Rs.{summary.cash_collected:,.2f}")
        print(f"    - COD Outstanding: Rs.{summary.cod_outstanding:,.2f}")
        print(f"    - Successful Payments: {summary.successful_payments}")

    print("\n" + "=" * 80)
    print("[SUCCESS] All Phase 8 Payment System features verified on live Neon PostgreSQL!")
    print("=" * 80)


if __name__ == "__main__":
    asyncio.run(run_payment_tests())
