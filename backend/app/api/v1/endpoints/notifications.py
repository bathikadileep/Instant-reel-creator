import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.database import get_db
from app.core.exceptions import NotFoundException
from app.models.schema_models import User
from app.repositories.device_token_repository import DeviceTokenRepository
from app.repositories.notification_repository import NotificationRepository
from app.schemas.notification import (
    DeviceTokenRegisterRequest,
    DeviceTokenResponse,
    NotificationListResponse,
    NotificationResponse,
    SendNotificationRequest,
    UnreadCountResponse,
)
from app.services.fcm_service import FCMService

router = APIRouter()


@router.post(
    "/devices",
    response_model=DeviceTokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Register Device Token for FCM",
    description="Registers or updates the FCM registration token for the currently authenticated user device.",
)
async def register_device_token(
    request: DeviceTokenRegisterRequest,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DeviceTokenResponse:
    repo = DeviceTokenRepository(db)
    token = await repo.register_device_token(
        user_id=current_user.id,
        fcm_token=request.fcm_token,
        platform=request.platform,
        device_name=request.device_name,
    )
    return DeviceTokenResponse.model_validate(token)


@router.delete(
    "/devices/{fcm_token}",
    status_code=status.HTTP_200_OK,
    summary="Unregister Device Token",
    description="Deactivates an FCM device token upon client logout.",
)
async def unregister_device_token(
    fcm_token: str,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = DeviceTokenRepository(db)
    success = await repo.deactivate_token(fcm_token)
    return {"status": "success", "deactivated": success}


@router.get(
    "",
    response_model=NotificationListResponse,
    include_in_schema=False,
)
@router.get(
    "/",
    response_model=NotificationListResponse,
    summary="List In-App Notifications",
    description="Returns notifications for current authenticated user with unread counter.",
)
async def list_notifications(
    unread_only: bool = Query(False, description="Filter only unread notifications"),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db),
) -> NotificationListResponse:
    repo = NotificationRepository(db)
    items = await repo.get_user_notifications(
        user_id=current_user.id,
        unread_only=unread_only,
        limit=limit,
    )
    unread_count = await repo.get_unread_count(current_user.id)
    return NotificationListResponse(
        items=[NotificationResponse.model_validate(i) for i in items],
        total=len(items),
        unread_count=unread_count,
    )


@router.get(
    "/unread-count",
    response_model=UnreadCountResponse,
    summary="Get Unread Notifications Count",
)
async def get_unread_count(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UnreadCountResponse:
    repo = NotificationRepository(db)
    count = await repo.get_unread_count(current_user.id)
    return UnreadCountResponse(unread_count=count)


@router.put(
    "/{notification_id}/read",
    response_model=NotificationResponse,
    summary="Mark Notification as Read",
)
async def mark_notification_read(
    notification_id: uuid.UUID,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db),
) -> NotificationResponse:
    repo = NotificationRepository(db)
    notif = await repo.get_by_id(notification_id)
    if not notif or notif.user_id != current_user.id:
        raise NotFoundException("Notification not found")

    await repo.mark_as_read(notification_id)
    refreshed = await repo.get_by_id(notification_id)
    return NotificationResponse.model_validate(refreshed)


@router.put(
    "/read-all",
    summary="Mark All Notifications as Read",
)
async def mark_all_notifications_read(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = NotificationRepository(db)
    await repo.mark_all_as_read(current_user.id)
    return {"status": "success", "message": "All notifications marked as read"}


@router.post(
    "/test",
    response_model=NotificationResponse,
    summary="Send Test Push Notification",
    description="Dispatches a test push notification to the current user's registered devices.",
)
async def send_test_notification(
    request: SendNotificationRequest,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db),
) -> NotificationResponse:
    notif = await FCMService.send_push_notification(
        db=db,
        user_id=current_user.id,
        title=request.title,
        body=request.body,
        notification_type=request.type,
        data=request.data or {"test": "true"},
    )
    return NotificationResponse.model_validate(notif)
