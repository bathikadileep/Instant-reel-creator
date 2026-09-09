"""Automated E2E Verification for Firebase Cloud Messaging (FCM) & Notifications Module.

Validates:
1. Device Token Registration & De-registration
2. Customer: Booking Confirmed alert
3. Customer: Creator Assigned alert
4. Customer: Creator Reached alert
5. Customer: Reel Delivered alert
6. Creator: New Booking alert
7. Creator: Booking Cancelled alert
8. Notification Read / Read All APIs & Unread counter
"""
import asyncio
import os
import sys
import uuid
from datetime import datetime, timezone
from decimal import Decimal

# Force utf-8 encoding on Windows consoles
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models.schema_models import (
    Booking,
    BookingStatus,
    CreatorProfile,
    DeviceToken,
    Notification,
    Package,
    User,
    UserRole,
)
from app.repositories.device_token_repository import DeviceTokenRepository
from app.repositories.notification_repository import NotificationRepository
from app.services.booking_service import BookingService
from app.services.fcm_service import FCMService, dispatched_notifications_log


async def run_fcm_e2e_tests():
    print("\n" + "=" * 80)
    print("STARTING FIREBASE CLOUD MESSAGING (FCM) & NOTIFICATION SYSTEM E2E TESTS")
    print("=" * 80)

    async with AsyncSessionLocal() as db:
        # 1. Setup Test Users
        res = await db.execute(select(User).where(User.mobile == "+919876500001"))
        customer = res.scalar_one_or_none()
        if not customer:
            customer = User(
                mobile="+919876500001",
                name="Test Customer",
                role=UserRole.CUSTOMER,
                is_active=True,
            )
            db.add(customer)
            await db.commit()
            await db.refresh(customer)

        res = await db.execute(select(User).where(User.mobile == "+919876500002"))
        creator_user = res.scalar_one_or_none()
        if not creator_user:
            creator_user = User(
                mobile="+919876500002",
                name="Ramesh Videographer",
                role=UserRole.CREATOR,
                is_active=True,
            )
            db.add(creator_user)
            await db.commit()
            await db.refresh(creator_user)

        res = await db.execute(select(CreatorProfile).where(CreatorProfile.user_id == creator_user.id))
        creator_profile = res.scalar_one_or_none()
        if not creator_profile:
            creator_profile = CreatorProfile(
                user_id=creator_user.id,
                primary_city="Warangal",
                whatsapp_number="+919876500002",
                camera_gear="Sony FX3 + 24-70mm GM II",
                is_available=True,
            )
            db.add(creator_profile)
            await db.commit()

        # Get package
        res = await db.execute(select(Package).where(Package.is_deleted == False).limit(1))
        pkg = res.scalar_one_or_none()
        if not pkg:
            pkg = Package(
                name="10-Minute Rapid Reel",
                description="Instant on-site edited reel",
                price=Decimal("499.00"),
                reels_count=1,
                shoot_duration_minutes=30,
                delivery_time_minutes=10,
                is_active=True,
            )
            db.add(pkg)
            await db.commit()
            await db.refresh(pkg)

        device_repo = DeviceTokenRepository(db)
        notif_repo = NotificationRepository(db)

        # ----------------------------------------------------------------------
        # Test 1: Register Device Tokens (Customer & Creator)
        # ----------------------------------------------------------------------
        print("\n--- Test 1: Device Token Registration ---")
        customer_fcm_token = f"fcm_token_cust_{uuid.uuid4().hex[:16]}"
        creator_fcm_token = f"fcm_token_creator_{uuid.uuid4().hex[:16]}"

        cust_device = await device_repo.register_device_token(
            user_id=customer.id,
            fcm_token=customer_fcm_token,
            platform="android",
            device_name="Samsung Galaxy S24 Ultra",
        )
        assert cust_device.is_active is True
        assert cust_device.user_id == customer.id

        creator_device = await device_repo.register_device_token(
            user_id=creator_user.id,
            fcm_token=creator_fcm_token,
            platform="android",
            device_name="OnePlus 12 Pro",
        )
        assert creator_device.is_active is True
        assert creator_device.user_id == creator_user.id

        active_cust_tokens = await device_repo.get_active_tokens_for_user(customer.id)
        assert customer_fcm_token in active_cust_tokens

        active_creator_tokens = await device_repo.get_active_tokens_for_user(creator_user.id)
        assert creator_fcm_token in active_creator_tokens

        print(f"[+] Customer FCM Token registered: {customer_fcm_token} (Active: {len(active_cust_tokens)})")
        print(f"[+] Creator FCM Token registered: {creator_fcm_token} (Active: {len(active_creator_tokens)})")

        # ----------------------------------------------------------------------
        # Test 2: Customer: Booking Confirmed Notification
        # ----------------------------------------------------------------------
        print("\n--- Test 2: Customer - Booking Confirmed Alert ---")
        test_booking = Booking(
            booking_code=f"IR-FCM-{uuid.uuid4().hex[:4].upper()}",
            customer_id=customer.id,
            package_id=pkg.id,
            city="Warangal",
            location_address="NIT Warangal Main Gate",
            scheduled_at=datetime.now(timezone.utc),
            customer_whatsapp=customer.mobile,
            total_amount=pkg.price,
            advance_amount=Decimal("99.00"),
            remaining_amount=Decimal("400.00"),
            payment_status="advance_paid",
            status=BookingStatus.PENDING,
        )
        db.add(test_booking)
        await db.commit()
        await db.refresh(test_booking)

        notif_confirmed = await FCMService.notify_booking_confirmed(db, test_booking)
        assert notif_confirmed.user_id == customer.id
        assert notif_confirmed.type == "booking_confirmed"
        assert "Booking Confirmed" in notif_confirmed.title
        assert notif_confirmed.is_read is False
        print(f"[+] Booking Confirmed Notification sent: {notif_confirmed.title} -> {notif_confirmed.body}")

        # ----------------------------------------------------------------------
        # Test 3: Customer: Creator Assigned & Creator: New Booking Alert
        # ----------------------------------------------------------------------
        print("\n--- Test 3: Creator Assigned & New Booking Alerts ---")
        test_booking.creator_id = creator_user.id
        test_booking.status = BookingStatus.CREATOR_ASSIGNED
        await db.commit()

        notif_assigned = await FCMService.notify_creator_assigned(
            db=db,
            booking=test_booking,
            creator_name=creator_user.name,
        )
        assert notif_assigned.user_id == customer.id
        assert notif_assigned.type == "creator_assigned"
        print(f"[+] Creator Assigned Alert (to Customer): {notif_assigned.title} -> {notif_assigned.body}")

        notif_new_booking = await FCMService.notify_new_booking(
            db=db,
            booking=test_booking,
            creator_id=creator_user.id,
        )
        assert notif_new_booking.user_id == creator_user.id
        assert notif_new_booking.type == "new_booking"
        print(f"[+] New Booking Alert (to Creator): {notif_new_booking.title} -> {notif_new_booking.body}")

        # ----------------------------------------------------------------------
        # Test 4: Customer: Creator Reached Alert
        # ----------------------------------------------------------------------
        print("\n--- Test 4: Customer - Creator Reached Alert ---")
        test_booking.status = BookingStatus.ARRIVED_AT_LOCATION
        await db.commit()

        notif_reached = await FCMService.notify_creator_reached(
            db=db,
            booking=test_booking,
            creator_name=creator_user.name,
        )
        assert notif_reached.user_id == customer.id
        assert notif_reached.type == "creator_reached"
        assert "Arrived" in notif_reached.title
        print(f"[+] Creator Reached Alert: {notif_reached.title} -> {notif_reached.body}")

        # ----------------------------------------------------------------------
        # Test 5: Customer: Reel Delivered Alert
        # ----------------------------------------------------------------------
        print("\n--- Test 5: Customer - Reel Delivered to WhatsApp Alert ---")
        test_booking.status = BookingStatus.DELIVERED
        test_booking.delivery_status = "delivered"
        test_booking.delivered_at = datetime.now(timezone.utc)
        await db.commit()

        notif_delivered = await FCMService.notify_reel_delivered(
            db=db,
            booking=test_booking,
        )
        assert notif_delivered.user_id == customer.id
        assert notif_delivered.type == "reel_delivered"
        assert "Delivered" in notif_delivered.title
        print(f"[+] Reel Delivered Alert: {notif_delivered.title} -> {notif_delivered.body}")

        # ----------------------------------------------------------------------
        # Test 6: Creator & Customer: Booking Cancelled Alert
        # ----------------------------------------------------------------------
        print("\n--- Test 6: Creator & Customer - Booking Cancelled Alert ---")
        cancel_booking = Booking(
            booking_code=f"IR-FCM-CNCL-{uuid.uuid4().hex[:4].upper()}",
            customer_id=customer.id,
            creator_id=creator_user.id,
            package_id=pkg.id,
            city="Warangal",
            location_address="Kazipet Junction",
            scheduled_at=datetime.now(timezone.utc),
            customer_whatsapp=customer.mobile,
            total_amount=pkg.price,
            advance_amount=Decimal("99.00"),
            remaining_amount=Decimal("400.00"),
            payment_status="advance_paid",
            status=BookingStatus.CANCELLED,
        )
        db.add(cancel_booking)
        await db.commit()
        await db.refresh(cancel_booking)

        cancel_notifs = await FCMService.notify_booking_cancelled(
            db=db,
            booking=cancel_booking,
            reason="Customer requested schedule change",
        )
        assert len(cancel_notifs) == 2  # 1 for creator, 1 for customer
        assert any(n.user_id == creator_user.id for n in cancel_notifs)
        assert any(n.user_id == customer.id for n in cancel_notifs)
        print(f"[+] Booking Cancelled Alerts sent to both Creator & Customer ({len(cancel_notifs)} dispatched)")

        # ----------------------------------------------------------------------
        # Test 7: Notification In-App APIs (List, Unread Count, Mark Read)
        # ----------------------------------------------------------------------
        print("\n--- Test 7: In-App Notification Operations & Counter ---")
        unread_count = await notif_repo.get_unread_count(customer.id)
        assert unread_count >= 4
        print(f"[+] Customer Unread Count: {unread_count}")

        cust_notifs = await notif_repo.get_user_notifications(customer.id, limit=10)
        assert len(cust_notifs) >= 4
        print(f"[+] Fetched {len(cust_notifs)} customer in-app notifications")

        # Mark one as read
        first_notif = cust_notifs[0]
        await notif_repo.mark_as_read(first_notif.id)
        refreshed_first = await notif_repo.get_by_id(first_notif.id)
        assert refreshed_first.is_read is True
        assert refreshed_first.read_at is not None
        print(f"[+] Notification {first_notif.id} marked as read.")

        # Mark all as read
        await notif_repo.mark_all_as_read(customer.id)
        new_unread_count = await notif_repo.get_unread_count(customer.id)
        assert new_unread_count == 0
        print(f"[+] All customer notifications marked as read. New unread count: {new_unread_count}")

        # ----------------------------------------------------------------------
        # Test 8: Device Token De-registration (Logout simulation)
        # ----------------------------------------------------------------------
        print("\n--- Test 8: Device Token De-registration on Logout ---")
        deactivated = await device_repo.deactivate_token(customer_fcm_token)
        assert deactivated is True

        tokens_after_logout = await device_repo.get_active_tokens_for_user(customer.id)
        assert customer_fcm_token not in tokens_after_logout
        print(f"[+] Token {customer_fcm_token} successfully deactivated upon client logout.")

    print("\n" + "=" * 80)
    print("[SUCCESS] ALL 8 FIREBASE CLOUD MESSAGING & NOTIFICATION TESTS PASSED 100%!")
    print("=" * 80)


if __name__ == "__main__":
    asyncio.run(run_fcm_e2e_tests())
