import uuid
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.schema_models import DeviceToken
from app.repositories.base import BaseRepository


class DeviceTokenRepository(BaseRepository[DeviceToken]):
    def __init__(self, db: AsyncSession):
        super().__init__(DeviceToken, db)

    async def register_device_token(
        self,
        user_id: uuid.UUID,
        fcm_token: str,
        platform: str = "android",
        device_name: Optional[str] = None,
    ) -> DeviceToken:
        """Register or update an FCM device token for a user."""
        token_clean = fcm_token.strip()
        query = select(DeviceToken).where(DeviceToken.fcm_token == token_clean)
        result = await self.db.execute(query)
        existing = result.scalar_one_or_none()

        now = datetime.now(timezone.utc)
        if existing:
            existing.user_id = user_id
            existing.platform = platform
            if device_name:
                existing.device_name = device_name
            existing.is_active = True
            existing.is_deleted = False
            existing.last_used_at = now
            existing.updated_at = now
            await self.db.commit()
            await self.db.refresh(existing)
            return existing

        new_device = DeviceToken(
            user_id=user_id,
            fcm_token=token_clean,
            platform=platform,
            device_name=device_name,
            is_active=True,
            last_used_at=now,
        )
        self.db.add(new_device)
        await self.db.commit()
        await self.db.refresh(new_device)
        return new_device

    async def deactivate_token(self, fcm_token: str) -> bool:
        """Deactivate a token when reported unregistered by FCM or on logout."""
        token_clean = fcm_token.strip()
        stmt = (
            update(DeviceToken)
            .where(DeviceToken.fcm_token == token_clean)
            .values(is_active=False, updated_at=datetime.now(timezone.utc))
        )
        result = await self.db.execute(stmt)
        await self.db.commit()
        return result.rowcount > 0

    async def deactivate_user_tokens(self, user_id: uuid.UUID) -> None:
        """Deactivate all active device tokens for a specific user (e.g. account logout)."""
        stmt = (
            update(DeviceToken)
            .where(DeviceToken.user_id == user_id, DeviceToken.is_active == True)  # noqa: E712
            .values(is_active=False, updated_at=datetime.now(timezone.utc))
        )
        await self.db.execute(stmt)
        await self.db.commit()

    async def get_active_tokens_for_user(self, user_id: uuid.UUID) -> List[str]:
        """Fetch all active FCM registration token strings for a user."""
        query = select(DeviceToken.fcm_token).where(
            DeviceToken.user_id == user_id,
            DeviceToken.is_active == True,  # noqa: E712
            DeviceToken.is_deleted == False,  # noqa: E712
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_active_devices_for_user(self, user_id: uuid.UUID) -> List[DeviceToken]:
        """Fetch all active DeviceToken entity models for a user."""
        query = select(DeviceToken).where(
            DeviceToken.user_id == user_id,
            DeviceToken.is_active == True,  # noqa: E712
            DeviceToken.is_deleted == False,  # noqa: E712
        ).order_by(DeviceToken.last_used_at.desc())
        result = await self.db.execute(query)
        return list(result.scalars().all())
