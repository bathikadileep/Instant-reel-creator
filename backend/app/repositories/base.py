import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Generic, List, Optional, Type, TypeVar, Union
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.base import TimeStampedUUIDBase

ModelType = TypeVar("ModelType", bound=TimeStampedUUIDBase)


class BaseRepository(Generic[ModelType]):
    """
    Production-grade Generic Asynchronous Repository providing:
    - CRUD Operations
    - Automatic Soft Delete filtering
    - Pagination
    """

    def __init__(self, model: Type[ModelType], db: AsyncSession):
        self.model = model
        self.db = db

    async def get_by_id(
        self,
        id: uuid.UUID,
        include_deleted: bool = False,
    ) -> Optional[ModelType]:
        """Fetch a single record by UUID, excluding soft-deleted by default."""
        query = select(self.model).where(self.model.id == id)
        if not include_deleted and hasattr(self.model, "is_deleted"):
            query = query.where(self.model.is_deleted == False)  # noqa: E712
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def list(
        self,
        skip: int = 0,
        limit: int = 50,
        include_deleted: bool = False,
    ) -> List[ModelType]:
        """Fetch multiple records with pagination."""
        query = select(self.model)
        if not include_deleted and hasattr(self.model, "is_deleted"):
            query = query.where(self.model.is_deleted == False)  # noqa: E712
        query = query.offset(skip).limit(limit).order_by(self.model.created_at.desc())
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def count(self, include_deleted: bool = False) -> int:
        """Count total records."""
        query = select(func.count(self.model.id))
        if not include_deleted and hasattr(self.model, "is_deleted"):
            query = query.where(self.model.is_deleted == False)  # noqa: E712
        result = await self.db.execute(query)
        return result.scalar_one() or 0

    async def create(self, entity: ModelType) -> ModelType:
        """Add new entity to session and commit."""
        self.db.add(entity)
        await self.db.commit()
        await self.db.refresh(entity)
        return entity

    async def update(
        self,
        entity: ModelType,
        update_data: Union[Dict[str, Any], ModelType],
    ) -> ModelType:
        """Update existing entity."""
        if isinstance(update_data, dict):
            for field, value in update_data.items():
                if hasattr(entity, field):
                    setattr(entity, field, value)
        else:
            for column in entity.__table__.columns.keys():
                if hasattr(update_data, column):
                    val = getattr(update_data, column)
                    if val is not None:
                        setattr(entity, column, val)

        await self.db.commit()
        await self.db.refresh(entity)
        return entity

    async def soft_delete(self, id: uuid.UUID) -> bool:
        """Soft delete record by setting is_deleted=True and deleted_at."""
        entity = await self.get_by_id(id)
        if not entity:
            return False

        if hasattr(entity, "soft_delete"):
            entity.soft_delete()
        else:
            setattr(entity, "is_deleted", True)
            setattr(entity, "deleted_at", datetime.now(timezone.utc))

        await self.db.commit()
        return True

    async def hard_delete(self, id: uuid.UUID) -> bool:
        """Permanently delete record from database."""
        entity = await self.get_by_id(id, include_deleted=True)
        if not entity:
            return False
        await self.db.delete(entity)
        await self.db.commit()
        return True
