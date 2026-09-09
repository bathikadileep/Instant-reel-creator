"""fcm device tokens for push notifications

Revision ID: 006_fcm_device_tokens
Revises: 005_whatsapp_delivery_module
Create Date: 2026-09-09 14:45:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '006_fcm_device_tokens'
down_revision: Union[str, None] = '005_whatsapp_delivery_module'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'device_tokens',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('fcm_token', sa.String(length=512), nullable=False),
        sa.Column('platform', sa.String(length=50), server_default='android', nullable=False),
        sa.Column('device_name', sa.String(length=100), nullable=True),
        sa.Column('is_active', sa.Boolean(), server_default=sa.text('true'), nullable=False),
        sa.Column('last_used_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('is_deleted', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
    )

    op.create_index('ix_device_tokens_id', 'device_tokens', ['id'], unique=False)
    op.create_index('ix_device_tokens_user_id', 'device_tokens', ['user_id'], unique=False)
    op.create_index('ix_device_tokens_fcm_token', 'device_tokens', ['fcm_token'], unique=True)
    op.create_index('ix_device_tokens_is_active', 'device_tokens', ['is_active'], unique=False)
    op.create_index('ix_device_tokens_user_active', 'device_tokens', ['user_id', 'is_active'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_device_tokens_user_active', table_name='device_tokens')
    op.drop_index('ix_device_tokens_is_active', table_name='device_tokens')
    op.drop_index('ix_device_tokens_fcm_token', table_name='device_tokens')
    op.drop_index('ix_device_tokens_user_id', table_name='device_tokens')
    op.drop_index('ix_device_tokens_id', table_name='device_tokens')
    op.drop_table('device_tokens')
