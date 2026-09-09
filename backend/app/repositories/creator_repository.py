import uuid
from decimal import Decimal
from typing import List, Optional
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.schema_models import CreatorProfile, Review
from app.repositories.base import BaseRepository


class CreatorRepository(BaseRepository[CreatorProfile]):
    def __init__(self, db: AsyncSession):
        super().__init__(CreatorProfile, db)

    async def get_by_user_id(self, user_id: uuid.UUID) -> Optional[CreatorProfile]:
        query = (
            select(CreatorProfile)
            .options(selectinload(CreatorProfile.user))
            .where(
                CreatorProfile.user_id == user_id,
                CreatorProfile.is_deleted == False,  # noqa: E712
            )
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def get_available_in_city(
        self,
        city: str,
        limit: int = 20,
    ) -> List[CreatorProfile]:
        """Find active, available creators operating in the given city."""
        query = (
            select(CreatorProfile)
            .options(selectinload(CreatorProfile.user))
            .where(
                func.lower(CreatorProfile.primary_city) == city.strip().lower(),
                CreatorProfile.is_available == True,  # noqa: E712
                CreatorProfile.is_deleted == False,  # noqa: E712
            )
            .order_by(CreatorProfile.rating_avg.desc())
            .limit(limit)
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def toggle_availability(
        self,
        creator_id: uuid.UUID,
        is_available: bool,
    ) -> Optional[CreatorProfile]:
        creator = await self.get_by_id(creator_id)
        if not creator:
            return None
        creator.is_available = is_available
        await self.db.commit()
        await self.db.refresh(creator)
        return creator

    async def increment_reels_delivered(self, user_or_profile_id: uuid.UUID) -> None:
        await self.db.execute(
            update(CreatorProfile)
            .where(
                (CreatorProfile.user_id == user_or_profile_id) | (CreatorProfile.id == user_or_profile_id)
            )
            .values(total_reels_delivered=CreatorProfile.total_reels_delivered + 1)
        )

    async def recalculate_rating(self, creator_user_id: uuid.UUID) -> Decimal:
        """Compute new average rating from all reviews received."""
        query = select(func.avg(Review.rating)).where(
            Review.creator_id == creator_user_id,
            Review.is_deleted == False,  # noqa: E712
        )
        result = await self.db.execute(query)
        avg = result.scalar()
        if avg is not None:
            rounded_avg = Decimal(str(round(avg, 2)))
            await self.db.execute(
                update(CreatorProfile)
                .where(CreatorProfile.user_id == creator_user_id)
                .values(rating_avg=rounded_avg)
            )
            await self.db.commit()
            return rounded_avg
        return Decimal("5.00")
