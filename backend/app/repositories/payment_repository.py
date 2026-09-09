import uuid
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.schema_models import Payment, PaymentStatus
from app.repositories.base import BaseRepository


class PaymentRepository(BaseRepository[Payment]):
    def __init__(self, db: AsyncSession):
        super().__init__(Payment, db)

    async def get_by_booking_id(self, booking_id: uuid.UUID) -> List[Payment]:
        query = (
            select(Payment)
            .where(
                Payment.booking_id == booking_id,
                Payment.is_deleted == False,  # noqa: E712
            )
            .order_by(Payment.created_at.desc())
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_by_transaction_id(self, transaction_id: str) -> Optional[Payment]:
        query = select(Payment).where(
            Payment.transaction_id == transaction_id,
            Payment.is_deleted == False,  # noqa: E712
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def mark_payment_completed(
        self,
        payment_id: uuid.UUID,
        transaction_id: Optional[str] = None,
    ) -> Optional[Payment]:
        payment = await self.get_by_id(payment_id)
        if not payment:
            return None

        payment.status = PaymentStatus.COMPLETED
        payment.paid_at = datetime.now(timezone.utc)
        if transaction_id:
            payment.transaction_id = transaction_id

        await self.db.commit()
        await self.db.refresh(payment)
        return payment
