import asyncio
import os
import sys
import uuid
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.core.database import AsyncSessionLocal
from app.models.schema_models import BookingStatus, Package, User, UserRole
from app.schemas.booking import BookingCreateRequest, EventType
from app.services.booking_service import BookingService
from sqlalchemy import select


async def test_booking_management_system():
    print("[*] Starting Booking Management System E2E test on live Neon DB...")
    async with AsyncSessionLocal() as db:
        service = BookingService(db)

        # 1. Setup / Fetch Customer & Creator
        cust_res = await db.execute(select(User).where(User.mobile == "+919999911111"))
        customer = cust_res.scalar_one()

        creator_res = await db.execute(select(User).where(User.mobile == "+919876543210"))
        creator = creator_res.scalar_one()

        pkg_res = await db.execute(select(Package).where(Package.is_active == True).limit(1))
        package = pkg_res.scalar_one()

        # 2. Test Booking Creation
        print("\n--- 1. Testing Booking Creation ---")
        create_payload = BookingCreateRequest(
            package_id=package.id,
            event_type=EventType.SHOP_PROMOTION,
            city="Warangal",
            location_address="Hanamkonda Main Road, Near Public Gardens",
            scheduled_at=datetime.now(timezone.utc),
            customer_whatsapp="+919999911111",
            notes="Grand showroom opening reel",
        )
        created_booking = await service.create_booking(customer=customer, payload=create_payload)
        assert created_booking.booking_code.startswith("IR-")
        assert created_booking.status == BookingStatus.PENDING
        assert created_booking.city == "Warangal"
        print(f"[+] Booking Created: {created_booking.booking_code} | Status: {created_booking.status.value}")

        # 3. Test Booking Assignment
        print("\n--- 2. Testing Booking Assignment ---")
        assigned_booking = await service.assign_creator(
            booking_id=created_booking.id,
            creator_id=creator.id,
            assigned_by=creator,  # self-assignment or admin
            note="Assigned via automated matching engine",
        )
        assert assigned_booking.status == BookingStatus.ASSIGNED
        assert assigned_booking.creator_id == creator.id
        print(f"[+] Creator Assigned: {assigned_booking.creator.name} | Status: {assigned_booking.status.value}")

        # 4. Test Status Timeline
        print("\n--- 3. Testing Status Timeline ---")
        timeline = await service.get_booking_timeline(
            booking_id=created_booking.id,
            requesting_user=customer,
        )
        assert timeline.booking_code == created_booking.booking_code
        assert len(timeline.events) >= 2
        print(f"[+] Timeline retrieved for {timeline.booking_code} ({len(timeline.events)} events):")
        for ev in timeline.events:
            print(f"    - [{ev.timestamp.strftime('%H:%M:%S')}] {ev.title} (by {ev.changed_by_name or 'System'}): {ev.note}")

        # 5. Test Filtered Search & History
        print("\n--- 4. Testing Filtered History Query ---")
        bookings, total = await service.get_filtered_bookings(
            user=customer,
            city="Warangal",
            search_query="Hanamkonda",
            limit=10,
        )
        assert total >= 1
        print(f"[+] Filtered search matched {total} bookings for city 'Warangal' with query 'Hanamkonda'")

        # 6. Test Booking Cancellation
        print("\n--- 5. Testing Booking Cancellation ---")
        cancelled = await service.cancel_booking(
            booking_id=created_booking.id,
            cancelled_by=customer,
            reason="Grand opening rescheduled due to heavy rain",
            note="Will rebook next weekend",
        )
        assert cancelled.status == BookingStatus.CANCELLED
        print(f"[+] Booking Cancelled: {cancelled.booking_code} | Status: {cancelled.status.value}")

        # 7. Verify Updated Timeline with Cancellation
        print("\n--- 6. Verifying Final Timeline Audit ---")
        final_timeline = await service.get_booking_timeline(
            booking_id=created_booking.id,
            requesting_user=customer,
        )
        assert final_timeline.current_status == "cancelled"
        assert len(final_timeline.events) >= 3
        last_event = final_timeline.events[-1]
        print(f"[+] Final Audit Event: {last_event.title} | {last_event.note}")

        print("\n[SUCCESS] All Booking Management System backend features (Create, Assign, Cancel, History, Timeline) verified on live Neon PostgreSQL!")


if __name__ == "__main__":
    asyncio.run(test_booking_management_system())
