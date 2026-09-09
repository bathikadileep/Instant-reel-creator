"""payment module and cod configuration

Revision ID: 004_payment_module_and_cod
Revises: 003_creator_workflow_statuses
Create Date: 2026-09-09 13:00:00.000000

"""
from typing import Sequence, Union
import uuid
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '004_payment_module_and_cod'
down_revision: Union[str, None] = '003_creator_workflow_statuses'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Update/Add enum values
    with op.get_context().autocommit_block():
        op.execute(sa.text("""
            DO $$ BEGIN
                CREATE TYPE payment_method AS ENUM ('razorpay_full', 'cod_with_advance');
            EXCEPTION
                WHEN duplicate_object THEN null;
            END $$;
        """))
        for val in ['advance_paid', 'paid']:
            op.execute(sa.text(f"ALTER TYPE payment_status ADD VALUE IF NOT EXISTS '{val}';"))

    # 2. Add payment columns to bookings table
    op.add_column('bookings', sa.Column('payment_method', sa.String(50), nullable=True))
    op.add_column('bookings', sa.Column('total_amount', sa.Numeric(10, 2), nullable=True))
    op.add_column('bookings', sa.Column('advance_amount', sa.Numeric(10, 2), server_default='0.00', nullable=False))
    op.add_column('bookings', sa.Column('remaining_amount', sa.Numeric(10, 2), server_default='0.00', nullable=False))
    op.add_column('bookings', sa.Column('payment_status', sa.String(50), server_default='pending', nullable=False))
    op.add_column('bookings', sa.Column('cash_collected', sa.Boolean(), server_default='false', nullable=False))
    op.add_column('bookings', sa.Column('cash_collected_at', sa.DateTime(timezone=True), nullable=True))

    op.create_index('ix_bookings_payment_status', 'bookings', ['payment_status'])
    op.create_index('ix_bookings_payment_method', 'bookings', ['payment_method'])

    # 3. Add columns to payments table
    op.add_column('payments', sa.Column('payment_method', sa.String(50), nullable=True))
    op.add_column('payments', sa.Column('razorpay_order_id', sa.String(255), nullable=True))
    op.add_column('payments', sa.Column('razorpay_payment_id', sa.String(255), nullable=True))
    op.add_column('payments', sa.Column('razorpay_signature', sa.String(500), nullable=True))
    op.add_column('payments', sa.Column('failure_reason', sa.Text(), nullable=True))

    op.create_index('ix_payments_razorpay_order_id', 'payments', ['razorpay_order_id'])
    op.create_index('ix_payments_razorpay_payment_id', 'payments', ['razorpay_payment_id'], unique=True)

    # 4. Create payment_configs table
    op.create_table(
        'payment_configs',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('cod_enabled', sa.Boolean(), server_default='true', nullable=False),
        sa.Column('cod_minimum_advance', sa.Numeric(10, 2), server_default='100.00', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('is_deleted', sa.Boolean(), server_default='false', nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
    )

    # 5. Insert default config record if none exists
    default_config_id = str(uuid.uuid4())
    op.execute(sa.text(f"""
        INSERT INTO payment_configs (id, cod_enabled, cod_minimum_advance, created_at, updated_at, is_deleted)
        VALUES ('{default_config_id}'::uuid, true, 100.00, NOW(), NOW(), false)
        ON CONFLICT (id) DO NOTHING;
    """))


def downgrade() -> None:
    op.drop_table('payment_configs')
    op.drop_index('ix_payments_razorpay_payment_id', table_name='payments')
    op.drop_index('ix_payments_razorpay_order_id', table_name='payments')
    op.drop_column('payments', 'failure_reason')
    op.drop_column('payments', 'razorpay_signature')
    op.drop_column('payments', 'razorpay_payment_id')
    op.drop_column('payments', 'razorpay_order_id')
    op.drop_column('payments', 'payment_method')

    op.drop_index('ix_bookings_payment_method', table_name='bookings')
    op.drop_index('ix_bookings_payment_status', table_name='bookings')
    op.drop_column('bookings', 'cash_collected_at')
    op.drop_column('bookings', 'cash_collected')
    op.drop_column('bookings', 'payment_status')
    op.drop_column('bookings', 'remaining_amount')
    op.drop_column('bookings', 'advance_amount')
    op.drop_column('bookings', 'total_amount')
    op.drop_column('bookings', 'payment_method')
