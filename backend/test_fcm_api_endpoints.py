"""Test Notification API Endpoints directly using FastAPI TestClient / httpx."""
import os
import sys
import uuid

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

import asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.core.security import create_access_token
from app.core.database import AsyncSessionLocal
from app.models.schema_models import User, UserRole
from sqlalchemy import select

async def test_notification_endpoints():
    print("\n" + "=" * 70)
    print("TESTING FASTAPI NOTIFICATION REST API ENDPOINTS")
    print("=" * 70)

    async with AsyncSessionLocal() as db:
        res = await db.execute(select(User).where(User.mobile == "+919876500001"))
        customer = res.scalar_one_or_none()
        assert customer is not None, "Customer user not found. Run E2E test first."

    # Generate JWT token for test customer
    access_token = create_access_token(
        subject=str(customer.id),
        role=customer.role.value,
        claims={"mobile": customer.mobile},
    )
    headers = {"Authorization": f"Bearer {access_token}"}

    test_device_token = f"test_device_{uuid.uuid4().hex[:12]}"

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test", follow_redirects=True) as client:
        # 1. Register Device Token
        print("\n1. Testing POST /api/v1/notifications/devices...")
        resp = await client.post(
            "/api/v1/notifications/devices",
            json={
                "fcm_token": test_device_token,
                "device_type": "android",
                "device_name": "Google Pixel 8 Pro",
            },
            headers=headers,
        )
        assert resp.status_code == 200, f"Device registration failed: {resp.text}"
        data = resp.json()
        assert data["fcm_token"] == test_device_token
        print(f"   [PASS] Device token registered: {data['device_name']} ({data['device_type']})")

        # 2. Trigger Test Notification
        print("\n2. Testing POST /api/v1/notifications/test...")
        resp = await client.post(
            "/api/v1/notifications/test",
            json={
                "title": "Shoot Update: Creator En Route",
                "body": "Videographer is 5 minutes away from your location.",
                "type": "creator_reached",
                "data": {"booking_id": str(uuid.uuid4()), "eta": "5 mins"},
            },
            headers=headers,
        )
        assert resp.status_code == 200, f"Test notification failed: {resp.text}"
        notif_data = resp.json()
        notif_id = notif_data["id"]
        assert notif_data["type"] == "creator_reached"
        print(f"   [PASS] Notification generated with ID: {notif_id}")

        # 3. Get Unread Count
        print("\n3. Testing GET /api/v1/notifications/unread-count...")
        resp = await client.get("/api/v1/notifications/unread-count", headers=headers)
        assert resp.status_code == 200
        count_data = resp.json()
        assert count_data["unread_count"] >= 1
        print(f"   [PASS] Unread count: {count_data['unread_count']}")

        # 4. List Notifications
        print("\n4. Testing GET /api/v1/notifications/...")
        resp = await client.get("/api/v1/notifications/?page=1&limit=10", headers=headers)
        assert resp.status_code == 200
        list_data = resp.json()
        assert "items" in list_data
        assert len(list_data["items"]) > 0
        print(f"   [PASS] Retrieved {len(list_data['items'])} items (Total: {list_data['total']})")

        # 5. Mark Single Notification as Read
        print(f"\n5. Testing PUT /api/v1/notifications/{notif_id}/read...")
        resp = await client.put(f"/api/v1/notifications/{notif_id}/read", headers=headers)
        assert resp.status_code == 200
        read_data = resp.json()
        assert read_data["is_read"] is True
        print(f"   [PASS] Notification {notif_id} marked as read.")

        # 6. Mark All as Read
        print("\n6. Testing PUT /api/v1/notifications/read-all...")
        resp = await client.put("/api/v1/notifications/read-all", headers=headers)
        assert resp.status_code == 200
        print("   [PASS] All notifications marked as read.")

        # Verify unread count is 0
        resp = await client.get("/api/v1/notifications/unread-count", headers=headers)
        assert resp.json()["unread_count"] == 0
        print("   [PASS] Verified unread count is now 0.")

        # 7. Unregister Device Token
        print(f"\n7. Testing DELETE /api/v1/notifications/devices/{test_device_token}...")
        resp = await client.delete(
            f"/api/v1/notifications/devices/{test_device_token}",
            headers=headers,
        )
        assert resp.status_code == 200
        print("   [PASS] Device token unregistered successfully.")

    print("\n" + "=" * 70)
    print("ALL NOTIFICATION REST API ENDPOINTS VALIDATED SUCCESSFULLY (100% PASS)!")
    print("=" * 70)

if __name__ == "__main__":
    asyncio.run(test_notification_endpoints())
