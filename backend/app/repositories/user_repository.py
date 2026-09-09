import uuid
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.schema_models import User, UserRole
from app.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    def __init__(self, db: AsyncSession):
        super().__init__(User, db)

    async def get_by_mobile(self, mobile: str) -> Optional[User]:
        query = select(User).where(
            User.mobile == mobile,
            User.is_deleted == False,  # noqa: E712
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> Optional[User]:
        query = select(User).where(
            User.email == email,
            User.is_deleted == False,  # noqa: E712
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def get_users_by_role(self, role: UserRole, limit: int = 50) -> List[User]:
        query = (
            select(User)
            .where(
                User.role == role,
                User.is_active == True,  # noqa: E712
                User.is_deleted == False,  # noqa: E712
            )
            .limit(limit)
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())
