"""add creator workflow statuses

Revision ID: 003_creator_workflow_statuses
Revises: 002_complete_schema
Create Date: 2026-09-09 11:20:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '003_creator_workflow_statuses'
down_revision: Union[str, None] = '002_complete_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    new_statuses = [
        'assigned',
        'on_the_way',
        'reached',
        'shooting_started',
        'shooting_completed',
        'editing_started',
        'editing_completed',
        'delivered',
        'rejected',
    ]

    with op.get_context().autocommit_block():
        for status_val in new_statuses:
            op.execute(sa.text(f"ALTER TYPE booking_status ADD VALUE IF NOT EXISTS '{status_val}';"))


def downgrade() -> None:
    pass
