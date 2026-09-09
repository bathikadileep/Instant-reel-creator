"""whatsapp delivery module

Revision ID: 005_whatsapp_delivery_module
Revises: 004_payment_module_and_cod
Create Date: 2026-09-09 14:30:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '005_whatsapp_delivery_module'
down_revision: Union[str, None] = '004_payment_module_and_cod'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add delivery_status column to bookings
    op.add_column(
        'bookings',
        sa.Column(
            'delivery_status',
            sa.String(length=50),
            server_default='pending',
            nullable=False,
            comment='pending, shared_on_whatsapp, delivered',
        ),
    )
    op.create_index('ix_bookings_delivery_status', 'bookings', ['delivery_status'])


def downgrade() -> None:
    op.drop_index('ix_bookings_delivery_status', table_name='bookings')
    op.drop_column('bookings', 'delivery_status')
