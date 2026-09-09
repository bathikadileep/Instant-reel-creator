"""create complete schema

Revision ID: 002_complete_schema
Revises: 001_auth_tables
Create Date: 2026-09-09 10:18:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '002_complete_schema'
down_revision: Union[str, None] = '001_auth_tables'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()

    # 1. Ensure Enums exist
    booking_status = postgresql.ENUM(
        'pending',
        'creator_assigned',
        'arrived_at_location',
        'shooting_in_progress',
        'editing',
        'delivered_on_whatsapp',
        'completed',
        'cancelled',
        name='booking_status',
        create_type=False,
    )
    booking_status.create(bind, checkfirst=True)

    payment_status = postgresql.ENUM(
        'pending',
        'completed',
        'failed',
        'refunded',
        name='payment_status',
        create_type=False,
    )
    payment_status.create(bind, checkfirst=True)

    # 2. Add audit & soft delete columns to existing users table
    op.add_column('users', sa.Column('email', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('is_deleted', sa.Boolean(), server_default=sa.text('false'), nullable=False))
    op.add_column('users', sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True))
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_is_deleted'), 'users', ['is_deleted'], unique=False)
    op.create_index('ix_users_role_active_deleted', 'users', ['role', 'is_active', 'is_deleted'], unique=False)

    # Add soft delete to existing support tables
    op.add_column('otp_verifications', sa.Column('is_deleted', sa.Boolean(), server_default=sa.text('false'), nullable=False))
    op.add_column('otp_verifications', sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True))
    op.create_index(op.f('ix_otp_verifications_is_deleted'), 'otp_verifications', ['is_deleted'], unique=False)

    op.add_column('refresh_tokens', sa.Column('is_deleted', sa.Boolean(), server_default=sa.text('false'), nullable=False))
    op.add_column('refresh_tokens', sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True))
    op.create_index(op.f('ix_refresh_tokens_is_deleted'), 'refresh_tokens', ['is_deleted'], unique=False)

    # 3. Create creator_profiles table
    op.create_table(
        'creator_profiles',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), unique=True, nullable=False),
        sa.Column('bio', sa.Text(), nullable=True),
        sa.Column('camera_gear', sa.String(length=255), nullable=True),
        sa.Column('primary_city', sa.String(length=50), nullable=False),
        sa.Column('service_areas', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
        sa.Column('whatsapp_number', sa.String(length=20), nullable=False),
        sa.Column('instagram_handle', sa.String(length=100), nullable=True),
        sa.Column('portfolio_urls', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
        sa.Column('is_available', sa.Boolean(), server_default=sa.text('true'), nullable=False),
        sa.Column('rating_avg', sa.Numeric(precision=3, scale=2), server_default='5.00', nullable=False),
        sa.Column('total_reels_delivered', sa.Integer(), server_default='0', nullable=False),
        sa.Column('verified_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('is_deleted', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(op.f('ix_creator_profiles_id'), 'creator_profiles', ['id'], unique=False)
    op.create_index(op.f('ix_creator_profiles_user_id'), 'creator_profiles', ['user_id'], unique=True)
    op.create_index(op.f('ix_creator_profiles_primary_city'), 'creator_profiles', ['primary_city'], unique=False)
    op.create_index(op.f('ix_creator_profiles_is_available'), 'creator_profiles', ['is_available'], unique=False)
    op.create_index(op.f('ix_creator_profiles_is_deleted'), 'creator_profiles', ['is_deleted'], unique=False)
    op.create_index('ix_creators_city_available', 'creator_profiles', ['primary_city', 'is_available', 'is_deleted'], unique=False)

    # 4. Create packages table
    op.create_table(
        'packages',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('price', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('reels_count', sa.Integer(), server_default='1', nullable=False),
        sa.Column('shoot_duration_minutes', sa.Integer(), server_default='30', nullable=False),
        sa.Column('delivery_time_minutes', sa.Integer(), server_default='10', nullable=False),
        sa.Column('features', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
        sa.Column('is_active', sa.Boolean(), server_default=sa.text('true'), nullable=False),
        sa.Column('is_deleted', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(op.f('ix_packages_id'), 'packages', ['id'], unique=False)
    op.create_index(op.f('ix_packages_is_active'), 'packages', ['is_active'], unique=False)
    op.create_index(op.f('ix_packages_is_deleted'), 'packages', ['is_deleted'], unique=False)

    # 5. Create bookings table
    op.create_table(
        'bookings',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('booking_code', sa.String(length=20), unique=True, nullable=False),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('creator_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('package_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('packages.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('status', postgresql.ENUM('pending', 'creator_assigned', 'arrived_at_location', 'shooting_in_progress', 'editing', 'delivered_on_whatsapp', 'completed', 'cancelled', name='booking_status', create_type=False), server_default='pending', nullable=False),
        sa.Column('city', sa.String(length=50), nullable=False),
        sa.Column('location_address', sa.Text(), nullable=False),
        sa.Column('latitude', sa.Numeric(precision=10, scale=7), nullable=True),
        sa.Column('longitude', sa.Numeric(precision=10, scale=7), nullable=True),
        sa.Column('scheduled_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('customer_whatsapp', sa.String(length=20), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('reel_url', sa.String(length=500), nullable=True),
        sa.Column('delivered_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('is_deleted', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(op.f('ix_bookings_id'), 'bookings', ['id'], unique=False)
    op.create_index(op.f('ix_bookings_booking_code'), 'bookings', ['booking_code'], unique=True)
    op.create_index(op.f('ix_bookings_customer_id'), 'bookings', ['customer_id'], unique=False)
    op.create_index(op.f('ix_bookings_creator_id'), 'bookings', ['creator_id'], unique=False)
    op.create_index(op.f('ix_bookings_package_id'), 'bookings', ['package_id'], unique=False)
    op.create_index(op.f('ix_bookings_status'), 'bookings', ['status'], unique=False)
    op.create_index(op.f('ix_bookings_city'), 'bookings', ['city'], unique=False)
    op.create_index(op.f('ix_bookings_scheduled_at'), 'bookings', ['scheduled_at'], unique=False)
    op.create_index(op.f('ix_bookings_is_deleted'), 'bookings', ['is_deleted'], unique=False)
    op.create_index('ix_bookings_status_city', 'bookings', ['status', 'city', 'is_deleted'], unique=False)
    op.create_index('ix_bookings_customer_status', 'bookings', ['customer_id', 'status'], unique=False)
    op.create_index('ix_bookings_creator_status', 'bookings', ['creator_id', 'status'], unique=False)

    # 6. Create booking_status_history table
    op.create_table(
        'booking_status_history',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('booking_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('bookings.id', ondelete='CASCADE'), nullable=False),
        sa.Column('status', postgresql.ENUM('pending', 'creator_assigned', 'arrived_at_location', 'shooting_in_progress', 'editing', 'delivered_on_whatsapp', 'completed', 'cancelled', name='booking_status', create_type=False), nullable=False),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('changed_by_user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('is_deleted', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(op.f('ix_booking_status_history_id'), 'booking_status_history', ['id'], unique=False)
    op.create_index(op.f('ix_booking_status_history_booking_id'), 'booking_status_history', ['booking_id'], unique=False)

    # 7. Create payments table
    op.create_table(
        'payments',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('booking_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('bookings.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('amount', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('currency', sa.String(length=3), server_default='INR', nullable=False),
        sa.Column('status', postgresql.ENUM('pending', 'completed', 'failed', 'refunded', name='payment_status', create_type=False), server_default='pending', nullable=False),
        sa.Column('provider', sa.String(length=50), server_default='razorpay', nullable=False),
        sa.Column('transaction_id', sa.String(length=255), unique=True, nullable=True),
        sa.Column('paid_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('is_deleted', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(op.f('ix_payments_id'), 'payments', ['id'], unique=False)
    op.create_index(op.f('ix_payments_booking_id'), 'payments', ['booking_id'], unique=False)
    op.create_index(op.f('ix_payments_customer_id'), 'payments', ['customer_id'], unique=False)
    op.create_index(op.f('ix_payments_status'), 'payments', ['status'], unique=False)
    op.create_index(op.f('ix_payments_transaction_id'), 'payments', ['transaction_id'], unique=True)
    op.create_index(op.f('ix_payments_is_deleted'), 'payments', ['is_deleted'], unique=False)
    op.create_index('ix_payments_booking_status', 'payments', ['booking_id', 'status'], unique=False)

    # 8. Create reviews table
    op.create_table(
        'reviews',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('booking_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('bookings.id', ondelete='CASCADE'), unique=True, nullable=False),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('creator_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('rating', sa.Integer(), nullable=False),
        sa.Column('comment', sa.Text(), nullable=True),
        sa.Column('turnaround_speed_rating', sa.Integer(), nullable=True),
        sa.Column('video_quality_rating', sa.Integer(), nullable=True),
        sa.Column('is_deleted', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(op.f('ix_reviews_id'), 'reviews', ['id'], unique=False)
    op.create_index(op.f('ix_reviews_booking_id'), 'reviews', ['booking_id'], unique=True)
    op.create_index(op.f('ix_reviews_customer_id'), 'reviews', ['customer_id'], unique=False)
    op.create_index(op.f('ix_reviews_creator_id'), 'reviews', ['creator_id'], unique=False)
    op.create_index(op.f('ix_reviews_is_deleted'), 'reviews', ['is_deleted'], unique=False)
    op.create_index('ix_reviews_creator_rating', 'reviews', ['creator_id', 'rating'], unique=False)

    # 9. Create notifications table
    op.create_table(
        'notifications',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('title', sa.String(length=150), nullable=False),
        sa.Column('body', sa.Text(), nullable=False),
        sa.Column('type', sa.String(length=50), nullable=False),
        sa.Column('data', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('is_read', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('read_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('is_deleted', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(op.f('ix_notifications_id'), 'notifications', ['id'], unique=False)
    op.create_index(op.f('ix_notifications_user_id'), 'notifications', ['user_id'], unique=False)
    op.create_index(op.f('ix_notifications_type'), 'notifications', ['type'], unique=False)
    op.create_index(op.f('ix_notifications_is_read'), 'notifications', ['is_read'], unique=False)
    op.create_index(op.f('ix_notifications_is_deleted'), 'notifications', ['is_deleted'], unique=False)
    op.create_index('ix_notifications_user_read_created', 'notifications', ['user_id', 'is_read', 'created_at'], unique=False)


def downgrade() -> None:
    op.drop_table('notifications')
    op.drop_table('reviews')
    op.drop_table('payments')
    op.drop_table('booking_status_history')
    op.drop_table('bookings')
    op.drop_table('packages')
    op.drop_table('creator_profiles')
    op.drop_column('users', 'email')
    op.drop_column('users', 'is_deleted')
    op.drop_column('users', 'deleted_at')
    op.execute("DROP TYPE IF EXISTS payment_status")
    op.execute("DROP TYPE IF EXISTS booking_status")
