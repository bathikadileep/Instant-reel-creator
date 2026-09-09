import asyncio
import sys
import uuid
from datetime import datetime, timezone
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.core.database import AsyncSessionLocal
from app.models.schema_models import (
    Booking,
    BookingStatus,
    CreatorProfile,
    Package,
    User,
    UserRole,
    BookingStatusHistory,
)
from app.repositories.booking_repository import BookingRepository
from sqlalchemy import select

async def test_creator_flow():
    print("[*] Starting live Neon PostgreSQL test for Creator Module...")
    async with AsyncSessionLocal() as db:
        repo = BookingRepository(db)
        
        # 1. Fetch or create test creator
        creator_res = await db.execute(select(User).where(User.mobile == "+919876543210"))
        creator = creator_res.scalar_one_or_none()
        if not creator:
            creator = User(
                id=uuid.uuid4(),
                mobile="+919876543210",
                name="Rajesh Kumar (Creator)",
                role=UserRole.CREATOR,
                is_active=True,
            )
            db.add(creator)
            await db.flush()
            
            profile = CreatorProfile(
                user_id=creator.id,
                bio="Cinematic reel specialist in Khammam & Warangal. 4K 60fps vertical reels with 10-min delivery.",
                camera_gear="Sony A7SIII, 24-70mm GM II, DJI Ronin RS3, DJI Mic 2",
                primary_city="Khammam",
                whatsapp_number="+919876543210",
                is_available=True,
                rating_avg=4.95,
            )
            db.add(profile)
            await db.commit()
            print(f"[+] Created test creator: {creator.name} ({creator.id})")
        else:
            print(f"[+] Using existing test creator: {creator.name}")

        # 2. Fetch or create test customer
        cust_res = await db.execute(select(User).where(User.mobile == "+919999911111"))
        customer = cust_res.scalar_one_or_none()
        if not customer:
            customer = User(
                id=uuid.uuid4(),
                mobile="+919999911111",
                name="Srikanth Rao",
                role=UserRole.CUSTOMER,
                is_active=True,
            )
            db.add(customer)
            await db.commit()
            print(f"[+] Created test customer: {customer.name}")

        # 3. Fetch a package
        pkg_res = await db.execute(select(Package).limit(1))
        package = pkg_res.scalar_one()

        # 4. Create pending booking
        booking = Booking(
            booking_code=await repo.generate_booking_code(),
            customer_id=customer.id,
            package_id=package.id,
            status=BookingStatus.PENDING,
            city="Khammam",
            location_address="Wyra Road, Near Jubilee Club, Khammam",
            customer_whatsapp="+919999911111",
            notes="Need high-energy retail launch reel with fast cuts",
            scheduled_at=datetime.now(timezone.utc),
        )
        created_booking = await repo.create_booking(booking)
        print(f"[+] Created test booking: {created_booking.booking_code} (Status: {created_booking.status.value})")

        # 5. Creator Accepts Booking
        accepted = await repo.accept_booking(created_booking.id, creator.id)
        assert accepted.status == BookingStatus.ASSIGNED
        print(f"[Step 1/8] ACCEPTED -> Status: {accepted.status.value}")

        # 6. Workflow Progressions:
        stages = [
            (BookingStatus.ON_THE_WAY, "Videographer is on the way with gear to Wyra Road"),
            (BookingStatus.REACHED, "Videographer reached the venue location"),
            (BookingStatus.SHOOTING_STARTED, "Camera rolling: Recording 4K vertical footage and hook shots"),
            (BookingStatus.SHOOTING_COMPLETED, "Shooting wrapped. 18 clips captured"),
            (BookingStatus.EDITING_STARTED, "10-Minute Rapid Edit started on iPad / MacBook"),
            (BookingStatus.EDITING_COMPLETED, "Export finished in 9:16 vertical 4K with audio sync"),
        ]

        for idx, (stage, note) in enumerate(stages, start=2):
            updated = await repo.update_creator_status(
                booking_id=created_booking.id,
                creator_user_id=creator.id,
                new_status=stage,
                note=note,
            )
            assert updated.status == stage
            print(f"[Step {idx}/8] {stage.value.upper()} -> {note}")

        # 7. Final Delivery with WhatsApp Reel URL
        delivered = await repo.update_creator_status(
            booking_id=created_booking.id,
            creator_user_id=creator.id,
            new_status=BookingStatus.DELIVERED,
            note="Reel delivered via WhatsApp with HD download link",
            reel_url="https://storage.instantreel.in/reels/khammam-launch-9075.mp4",
        )
        assert delivered.status == BookingStatus.DELIVERED
        assert delivered.reel_url is not None
        assert delivered.delivered_at is not None
        print(f"[Step 8/8] DELIVERED -> Reel URL: {delivered.reel_url} at {delivered.delivered_at}")

        # 8. Verify Dashboard Stats
        stats = await repo.get_creator_dashboard_stats(creator.id)
        print(f"[+] Creator Dashboard Metrics for {creator.name}:")
        print(f"    - Today Bookings: {stats['today_bookings_count']}")
        print(f"    - Completed Bookings: {stats['completed_bookings_count']}")
        print(f"    - Total Earnings: Rs.{stats['total_earnings']}")
        print(f"    - Today Earnings: Rs.{stats['today_earnings']}")
        print(f"    - Rating: {stats['rating_avg']} (Reviews: {stats['total_reviews']})")
        assert stats["completed_bookings_count"] >= 1
        print("[SUCCESS] All Creator Module backend operations and 8-stage lifecycle verified on live Neon database!")

if __name__ == "__main__":
    asyncio.run(test_creator_flow())
