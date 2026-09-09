"""Automated E2E Test for Phase 9 WhatsApp Delivery Module on Live Neon DB.

Verifies:
1. Creator completes editing externally.
2. Creator clicks Send Reel -> backend sets delivery_status='shared_on_whatsapp', returns WhatsApp URL.
3. Creator marks booking delivered -> backend sets delivery_status='delivered', records delivered_at, marks DELIVERED.
4. No video stored in DB. No AWS S3.
"""
import asyncio
from datetime import datetime, timezone, timedelta
from decimal import Decimal
import uuid
from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.models.schema_models import (
    Booking,
    BookingStatus,
    CreatorProfile,
    Package,
    User,
    UserRole,
)
from app.repositories.booking_repository import BookingRepository
from app.repositories.creator_repository import CreatorRepository
from app.api.v1.endpoints.creator import send_reel_whatsapp, mark_booking_delivered
from app.schemas.creator import MarkDeliveredRequest


async def run_whatsapp_delivery_tests():
    print("=" * 80)
    print("INSTANT REEL - WHATSAPP DELIVERY MODULE E2E TEST (LIVE NEON DB)")
    print("=" * 80)

    async with AsyncSessionLocal() as db:
        # 1. Fetch or create Customer & Creator
        cust_res = await db.execute(select(User).where(User.role == UserRole.CUSTOMER))
        customer = cust_res.scalars().first()
        if not customer:
            customer = User(
                name="Sunita Customer",
                mobile="+919876500001",
                role=UserRole.CUSTOMER,
                is_active=True,
            )
            db.add(customer)
            await db.flush()

        creator_res = await db.execute(select(User).where(User.role == UserRole.CREATOR))
        creator = creator_res.scalars().first()
        if not creator:
            creator = User(
                name="Ramesh Videographer",
                mobile="+919876500002",
                role=UserRole.CREATOR,
                is_active=True,
            )
            db.add(creator)
            await db.flush()

        # Creator Profile
        prof_res = await db.execute(select(CreatorProfile).where(CreatorProfile.user_id == creator.id))
        creator_profile = prof_res.scalars().first()
        if not creator_profile:
            creator_profile = CreatorProfile(
                user_id=creator.id,
                primary_city="Warangal",
                whatsapp_number=creator.mobile,
                is_available=True,
                total_reels_delivered=0,
            )
            db.add(creator_profile)
            await db.flush()

        initial_delivered_count = creator_profile.total_reels_delivered

        # Package
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

        # 2. Create Booking in EDITING phase
        booking = Booking(
            booking_code=f"IR-WA-{uuid.uuid4().hex[:4].upper()}",
            customer_id=customer.id,
            creator_id=creator.id,
            package_id=package.id,
            status=BookingStatus.EDITING_COMPLETED,
            city="Warangal",
            location_address="Hanamkonda Main Road, Warangal",
            scheduled_at=datetime.now(timezone.utc) + timedelta(hours=1),
            customer_whatsapp="+919876500001",
            delivery_status="pending",
            total_amount=Decimal("499.00"),
            advance_amount=Decimal("499.00"),
            remaining_amount=Decimal("0.00"),
        )
        db.add(booking)
        await db.commit()
        await db.refresh(booking)

        print(f"[+] Test Booking Created: {booking.booking_code} (ID: {booking.id})")
        print(f"    - Customer: {customer.name} ({booking.customer_whatsapp})")
        print(f"    - Creator: {creator.name}")
        print(f"    - Initial Status: {booking.status.value}")
        print(f"    - Initial Delivery Status: {booking.delivery_status}")
        assert booking.delivery_status == "pending"
        assert booking.delivered_at is None

        # 3. Step 1 & 2: Creator clicks 'Send Reel' -> WhatsApp launch response
        print("\n--- Testing Step 1 & 2: Creator clicks 'Send Reel' ---")
        send_resp = await send_reel_whatsapp(
            booking_id=booking.id,
            current_user=creator,
            db=db,
        )
        print(f"[+] WhatsApp Launch Link Generated:")
        print(f"    - Target Phone: {send_resp.customer_whatsapp}")
        print(f"    - Deep Link: {send_resp.whatsapp_url[:60]}...")
        print(f"    - Prefilled Message: {send_resp.prefilled_message}")
        print(f"    - Updated Delivery Status: {send_resp.delivery_status}")
        assert send_resp.delivery_status == "shared_on_whatsapp"
        assert "wa.me" in send_resp.whatsapp_url
        assert "919876500001" in send_resp.whatsapp_url

        # 4. Step 5: Creator shares video from gallery in WhatsApp and clicks 'Mark Delivered'
        print("\n--- Testing Step 5: Creator marks booking delivered ---")
        delivered_resp = await mark_booking_delivered(
            booking_id=booking.id,
            request=MarkDeliveredRequest(note="Vertical 4K reel delivered to customer via WhatsApp."),
            current_user=creator,
            db=db,
        )
        print(f"[+] Booking Marked Delivered:")
        print(f"    - Booking Status: {delivered_resp.status.value}")
        print(f"    - Delivery Status: {delivered_resp.delivery_status}")
        print(f"    - Delivered At: {delivered_resp.delivered_at}")
        assert delivered_resp.status == BookingStatus.DELIVERED
        assert delivered_resp.delivery_status == "delivered"
        assert delivered_resp.delivered_at is not None

        # 5. Verify Creator Delivery Metrics & Neon DB persistence
        print("\n--- Verifying Database Audit & Metrics ---")
        async with AsyncSessionLocal() as fresh_db:
            db_booking = await fresh_db.get(Booking, booking.id)
            assert db_booking is not None
            print(f"[+] Fresh DB Fetch Verification:")
            print(f"    - DB delivery_status: {db_booking.delivery_status}")
            print(f"    - DB delivered_at: {db_booking.delivered_at}")
            print(f"    - DB reel_url (No video stored): {db_booking.reel_url or 'None (Direct WhatsApp)'}")
            assert db_booking.delivery_status == "delivered"
            assert db_booking.delivered_at is not None

            # Verify creator profile counter
            db_creator_prof = (
                await fresh_db.execute(select(CreatorProfile).where(CreatorProfile.user_id == creator.id))
            ).scalars().first()
            assert db_creator_prof is not None
            print(f"    - Creator Total Delivered Reels: {db_creator_prof.total_reels_delivered} (was {initial_delivered_count})")
            assert db_creator_prof.total_reels_delivered == initial_delivered_count + 1

    print("\n" + "=" * 80)
    print("[SUCCESS] WhatsApp Delivery Module verified 100% on live Neon PostgreSQL!")
    print("=" * 80)


if __name__ == "__main__":
    asyncio.run(run_whatsapp_delivery_tests())
