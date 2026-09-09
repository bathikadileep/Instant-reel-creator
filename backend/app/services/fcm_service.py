import json
import logging
import uuid
from typing import Any, Dict, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.schema_models import Booking, Notification
from app.repositories.device_token_repository import DeviceTokenRepository
from app.repositories.notification_repository import NotificationRepository

logger = logging.getLogger("instant_reel.fcm")

# In-memory history of dispatched notifications (useful for test assertions and dev inspection)
dispatched_notifications_log: List[Dict[str, Any]] = []

# Check for Firebase Admin SDK availability
_firebase_initialized = False

try:
    import firebase_admin
    from firebase_admin import credentials, messaging

    if settings.FIREBASE_SERVICE_ACCOUNT_JSON:
        cred_dict = json.loads(settings.FIREBASE_SERVICE_ACCOUNT_JSON)
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info("[FCM] Firebase Admin SDK initialized via inline service account JSON.")
    elif settings.FIREBASE_CREDENTIALS_PATH:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info(f"[FCM] Firebase Admin SDK initialized from file: {settings.FIREBASE_CREDENTIALS_PATH}")
    else:
        logger.info("[FCM] No Firebase credentials provided. Running in Development / Mock Push Mode.")
except ImportError:
    logger.info("[FCM] firebase-admin package not installed. Running in Development / Mock Push Mode.")
except Exception as e:
    logger.warning(f"[FCM] Failed to initialize Firebase Admin SDK: {e}. Falling back to Mock Push Mode.")


class FCMService:
    @staticmethod
    def is_live() -> bool:
        return _firebase_initialized and settings.FCM_ENABLED

    @classmethod
    async def send_push_notification(
        cls,
        db: AsyncSession,
        user_id: uuid.UUID,
        title: str,
        body: str,
        notification_type: str,
        data: Optional[Dict[str, Any]] = None,
    ) -> Notification:
        """
        1. Persists the in-app Notification record in the database.
        2. Dispatches FCM push notification to all active devices registered for the user.
        3. Cleans up any invalid tokens reported by FCM.
        """
        notif_repo = NotificationRepository(db)
        device_repo = DeviceTokenRepository(db)

        # 1. Create and persist Notification record
        notification = Notification(
            user_id=user_id,
            title=title,
            body=body,
            type=notification_type,
            data=data or {},
        )
        db.add(notification)
        await db.commit()
        await db.refresh(notification)

        # 2. Get active tokens for target user
        active_tokens = await device_repo.get_active_tokens_for_user(user_id)

        # Prepare string data payload for FCM
        fcm_data = {
            "notification_id": str(notification.id),
            "type": notification_type,
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
        }
        if data:
            for k, v in data.items():
                fcm_data[str(k)] = str(v)

        dispatch_record = {
            "notification_id": str(notification.id),
            "user_id": str(user_id),
            "title": title,
            "body": body,
            "type": notification_type,
            "data": fcm_data,
            "tokens_count": len(active_tokens),
            "is_live_fcm": cls.is_live(),
        }
        dispatched_notifications_log.append(dispatch_record)

        if not active_tokens:
            logger.info(f"[FCM] User {user_id} has no registered active devices. Notification {notification.id} stored in-app.")
            return notification

        # 3. Dispatch Push Notification
        if cls.is_live():
            try:
                # Use firebase_admin messaging
                message = messaging.MulticastMessage(
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                    ),
                    data=fcm_data,
                    tokens=active_tokens,
                )
                response = messaging.send_each_for_multicast(message)
                logger.info(
                    f"[FCM LIVE] Sent to {len(active_tokens)} tokens for user {user_id}: "
                    f"{response.success_count} success, {response.failure_count} failures."
                )

                # Clean up expired/unregistered tokens
                for idx, resp in enumerate(response.responses):
                    if not resp.success and resp.exception:
                        failed_token = active_tokens[idx]
                        logger.warning(f"[FCM LIVE] Deactivating failed token: {resp.exception}")
                        await device_repo.deactivate_token(failed_token)
            except Exception as e:
                logger.error(f"[FCM LIVE ERROR] Failed sending push notification: {e}")
        else:
            logger.info(
                f"[FCM MOCK] Push dispatched for user {user_id} across {len(active_tokens)} active tokens: "
                f"Title='{title}' Type='{notification_type}' Payload={fcm_data}"
            )

        return notification

    # ==========================================================================
    # Customer Lifecycle Notifications
    # ==========================================================================

    @classmethod
    async def notify_booking_confirmed(
        cls,
        db: AsyncSession,
        booking: Booking,
    ) -> Notification:
        """Customer: Booking Confirmed alert."""
        package_name = booking.package.name if booking.package else "10-Minute Rapid Reel"
        title = "Booking Confirmed! 🎬"
        body = (
            f"Your Instant Reel shoot for {package_name} in {booking.city} is confirmed! "
            f"Videographer matching in progress."
        )
        data = {
            "booking_id": str(booking.id),
            "booking_code": booking.booking_code,
            "type": "booking_confirmed",
            "city": booking.city,
        }
        return await cls.send_push_notification(
            db=db,
            user_id=booking.customer_id,
            title=title,
            body=body,
            notification_type="booking_confirmed",
            data=data,
        )

    @classmethod
    async def notify_creator_assigned(
        cls,
        db: AsyncSession,
        booking: Booking,
        creator_name: str,
    ) -> Notification:
        """Customer: Creator Assigned alert."""
        title = "Creator Assigned! 🎥"
        body = (
            f"{creator_name} has been assigned as your videographer for booking {booking.booking_code}. "
            f"They are gearing up for your shoot."
        )
        data = {
            "booking_id": str(booking.id),
            "booking_code": booking.booking_code,
            "type": "creator_assigned",
            "creator_id": str(booking.creator_id) if booking.creator_id else "",
            "creator_name": creator_name,
        }
        return await cls.send_push_notification(
            db=db,
            user_id=booking.customer_id,
            title=title,
            body=body,
            notification_type="creator_assigned",
            data=data,
        )

    @classmethod
    async def notify_creator_reached(
        cls,
        db: AsyncSession,
        booking: Booking,
        creator_name: str,
    ) -> Notification:
        """Customer: Creator Reached Venue alert."""
        title = "Creator Has Arrived! 📍"
        body = (
            f"Your videographer {creator_name} has arrived at your location ({booking.location_address}) "
            f"and is ready to roll cameras!"
        )
        data = {
            "booking_id": str(booking.id),
            "booking_code": booking.booking_code,
            "type": "creator_reached",
            "creator_name": creator_name,
        }
        return await cls.send_push_notification(
            db=db,
            user_id=booking.customer_id,
            title=title,
            body=body,
            notification_type="creator_reached",
            data=data,
        )

    @classmethod
    async def notify_reel_delivered(
        cls,
        db: AsyncSession,
        booking: Booking,
    ) -> Notification:
        """Customer: Reel Delivered to WhatsApp alert."""
        title = "Your 4K Reel is Delivered! 🚀"
        body = (
            f"Your 4K rapid reel for booking {booking.booking_code} has been delivered directly via WhatsApp! "
            f"Check your chat to post and share."
        )
        data = {
            "booking_id": str(booking.id),
            "booking_code": booking.booking_code,
            "type": "reel_delivered",
            "delivery_status": booking.delivery_status,
        }
        return await cls.send_push_notification(
            db=db,
            user_id=booking.customer_id,
            title=title,
            body=body,
            notification_type="reel_delivered",
            data=data,
        )

    # ==========================================================================
    # Creator Lifecycle Notifications
    # ==========================================================================

    @classmethod
    async def notify_new_booking(
        cls,
        db: AsyncSession,
        booking: Booking,
        creator_id: uuid.UUID,
    ) -> Notification:
        """Creator: New Booking Assigned alert."""
        package_name = booking.package.name if booking.package else "Rapid Reel"
        title = "New Booking Assigned! ⚡"
        body = (
            f"New shoot {booking.booking_code} in {booking.city} for {package_name}. "
            f"Tap to view shoot details & accept."
        )
        data = {
            "booking_id": str(booking.id),
            "booking_code": booking.booking_code,
            "type": "new_booking",
            "city": booking.city,
        }
        return await cls.send_push_notification(
            db=db,
            user_id=creator_id,
            title=title,
            body=body,
            notification_type="new_booking",
            data=data,
        )

    @classmethod
    async def notify_booking_cancelled(
        cls,
        db: AsyncSession,
        booking: Booking,
        reason: Optional[str] = None,
    ) -> List[Notification]:
        """Creator & Customer: Booking Cancelled alert."""
        notifications = []
        reason_text = f" ({reason})" if reason else ""

        # Notify Creator if one was assigned
        if booking.creator_id:
            c_notif = await cls.send_push_notification(
                db=db,
                user_id=booking.creator_id,
                title="Booking Cancelled ⚠️",
                body=f"Booking {booking.booking_code} in {booking.city} has been cancelled{reason_text}.",
                notification_type="booking_cancelled",
                data={
                    "booking_id": str(booking.id),
                    "booking_code": booking.booking_code,
                    "type": "booking_cancelled",
                },
            )
            notifications.append(c_notif)

        # Notify Customer
        cust_notif = await cls.send_push_notification(
            db=db,
            user_id=booking.customer_id,
            title="Booking Cancelled",
            body=f"Your booking {booking.booking_code} in {booking.city} has been cancelled{reason_text}.",
            notification_type="booking_cancelled",
            data={
                "booking_id": str(booking.id),
                "booking_code": booking.booking_code,
                "type": "booking_cancelled",
            },
        )
        notifications.append(cust_notif)

        return notifications
