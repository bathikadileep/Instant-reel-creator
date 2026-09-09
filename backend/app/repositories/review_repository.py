import uuid
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.schema_models import Review
from app.repositories.base import BaseRepository
from app.repositories.creator_repository import CreatorRepository


class ReviewRepository(BaseRepository[Review]):
    def __init__(self, db: AsyncSession):
        super().__init__(Review, db)
        self.creator_repo = CreatorRepository(db)

    async def get_by_booking_id(self, booking_id: uuid.UUID) -> Optional[Review]:
        query = select(Review).where(
            Review.booking_id == booking_id,
            Review.is_deleted == False,  # noqa: E712
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def get_creator_reviews(
        self,
        creator_id: uuid.UUID,
        limit: int = 50,
    ) -> List[Review]:
        query = (
            select(Review)
            .options(selectinload(Review.customer))
            .where(
                Review.creator_id == creator_id,
                Review.is_deleted == False,  # noqa: E712
            )
            .order_by(Review.created_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def submit_review(self, review: Review) -> Review:
        """Add review and automatically recalculate creator's average rating."""
        self.db.add(review)
        await self.db.commit()
        await self.db.refresh(review)

        # Recalculate average rating on creator profile
        await self.creator_repo.recalculate_rating(review.creator_id)

        return review
