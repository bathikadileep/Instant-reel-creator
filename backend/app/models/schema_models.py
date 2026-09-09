import enum
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, List, Optional
from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TimeStampedUUIDBase


# ==============================================================================
# Enumerations
# ==============================================================================

class UserRole(str, enum.Enum):
    CUSTOMER = "customer"
    CREATOR = "creator"
    ADMIN = "admin"


class BookingStatus(str, enum.Enum):
    PENDING = "pending"
    # Creator Workflow Statuses
    ASSIGNED = "assigned"
    ON_THE_WAY = "on_the_way"
    REACHED = "reached"
    SHOOTING_STARTED = "shooting_started"
    SHOOTING_COMPLETED = "shooting_completed"
    EDITING_STARTED = "editing_started"
    EDITING_COMPLETED = "editing_completed"
    DELIVERED = "delivered"
    REJECTED = "rejected"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

    # Legacy Aliases
    CREATOR_ASSIGNED = "creator_assigned"
    ARRIVED_AT_LOCATION = "arrived_at_location"
    SHOOTING_IN_PROGRESS = "shooting_in_progress"
    EDITING = "editing"
    DELIVERED_ON_WHATSAPP = "delivered_on_whatsapp"


class PaymentMethod(str, enum.Enum):
    RAZORPAY_FULL = "razorpay_full"
    COD_WITH_ADVANCE = "cod_with_advance"


class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    ADVANCE_PAID = "advance_paid"
    PAID = "paid"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"


# ==============================================================================
# 1. User Model
# ==============================================================================

class User(TimeStampedUUIDBase):
    """
    Platform User (Customer, Reel Creator, or Admin).
    """
    __tablename__ = "users"

    name: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    mobile: Mapped[str] = mapped_column(
        String(20),
        unique=True,
        index=True,
        nullable=False,
    )
    email: Mapped[Optional[str]] = mapped_column(
        String(255),
        unique=True,
        index=True,
        nullable=True,
    )
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role", create_type=False, values_callable=lambda x: [e.value for e in x]),
        default=UserRole.CUSTOMER,
        nullable=False,
        index=True,
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )

    # Relationships
    creator_profile: Mapped[Optional["CreatorProfile"]] = relationship(
        "CreatorProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    bookings_as_customer: Mapped[List["Booking"]] = relationship(
        "Booking",
        foreign_keys="[Booking.customer_id]",
        back_populates="customer",
    )
    bookings_as_creator: Mapped[List["Booking"]] = relationship(
        "Booking",
        foreign_keys="[Booking.creator_id]",
        back_populates="creator",
    )
    payments: Mapped[List["Payment"]] = relationship(
        "Payment",
        back_populates="customer",
    )
    reviews_given: Mapped[List["Review"]] = relationship(
        "Review",
        foreign_keys="[Review.customer_id]",
        back_populates="customer",
    )
    reviews_received: Mapped[List["Review"]] = relationship(
        "Review",
        foreign_keys="[Review.creator_id]",
        back_populates="creator",
    )
    notifications: Mapped[List["Notification"]] = relationship(
        "Notification",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    refresh_tokens: Mapped[List["RefreshToken"]] = relationship(
        "RefreshToken",
        back_populates="user",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        Index("ix_users_role_active_deleted", "role", "is_active", "is_deleted"),
    )

    def __repr__(self) -> str:
        return f"<User {self.mobile} ({self.role})>"


# ==============================================================================
# 2. Creator Profile Model
# ==============================================================================

class CreatorProfile(TimeStampedUUIDBase):
    """
    Profile extension for professional reel creators in Maripeda, Mahabubabad,
    Khammam, and Warangal.
    """
    __tablename__ = "creator_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )
    bio: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    camera_gear: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
        comment="e.g. Sony A7IV, 24-70mm GM, DJI RS3 Gimbal, Wireless Mic",
    )
    primary_city: Mapped[str] = mapped_column(
        String(50),
        index=True,
        nullable=False,
        comment="Maripeda, Mahabubabad, Khammam, or Warangal",
    )
    service_areas: Mapped[list] = mapped_column(
        JSONB,
        default=list,
        nullable=False,
        comment="List of specific towns or pin codes serviced",
    )
    whatsapp_number: Mapped[str] = mapped_column(String(20), nullable=False)
    instagram_handle: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    portfolio_urls: Mapped[list] = mapped_column(
        JSONB,
        default=list,
        nullable=False,
        comment="Links to sample Instagram Reels / YouTube Shorts",
    )
    is_available: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        index=True,
        nullable=False,
    )
    rating_avg: Mapped[Decimal] = mapped_column(
        Numeric(3, 2),
        default=Decimal("5.00"),
        nullable=False,
    )
    total_reels_delivered: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False,
    )
    verified_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="creator_profile")

    __table_args__ = (
        Index("ix_creators_city_available", "primary_city", "is_available", "is_deleted"),
    )

    def __repr__(self) -> str:
        return f"<CreatorProfile city={self.primary_city} rating={self.rating_avg}>"


# ==============================================================================
# 3. Package Model
# ==============================================================================

class Package(TimeStampedUUIDBase):
    """
    Standardized instant reel booking packages (e.g. 10-Minute Rapid Delivery).
    """
    __tablename__ = "packages"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    price: Mapped[Decimal] = mapped_column(
        Numeric(10, 2),
        nullable=False,
        comment="Price in INR",
    )
    reels_count: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    shoot_duration_minutes: Mapped[int] = mapped_column(
        Integer,
        default=30,
        nullable=False,
    )
    delivery_time_minutes: Mapped[int] = mapped_column(
        Integer,
        default=10,
        nullable=False,
        comment="Rapid edit turnaround SLA in minutes (Instant Reel 10-minute promise)",
    )
    features: Mapped[list] = mapped_column(
        JSONB,
        default=list,
        nullable=False,
        comment="Package highlights and deliverables list",
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        index=True,
        nullable=False,
    )

    # Relationships
    bookings: Mapped[List["Booking"]] = relationship("Booking", back_populates="package")

    def __repr__(self) -> str:
        return f"<Package {self.name} - Rs.{self.price}>"


# ==============================================================================
# 4. Booking Model
# ==============================================================================

class Booking(TimeStampedUUIDBase):
    """
    Core booking record connecting a Customer, Creator, and Package.
    """
    __tablename__ = "bookings"

    booking_code: Mapped[str] = mapped_column(
        String(20),
        unique=True,
        index=True,
        nullable=False,
        comment="Human readable identifier, e.g. IR-2026-0001",
    )
    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        index=True,
        nullable=False,
    )
    creator_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    package_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("packages.id", ondelete="RESTRICT"),
        index=True,
        nullable=False,
    )
    status: Mapped[BookingStatus] = mapped_column(
        Enum(BookingStatus, name="booking_status", create_type=False, values_callable=lambda x: [e.value for e in x]),
        default=BookingStatus.PENDING,
        index=True,
        nullable=False,
    )
    city: Mapped[str] = mapped_column(
        String(50),
        index=True,
        nullable=False,
        comment="Maripeda, Mahabubabad, Khammam, or Warangal",
    )
    location_address: Mapped[str] = mapped_column(Text, nullable=False)
    latitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 7), nullable=True)
    longitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 7), nullable=True)
    scheduled_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        index=True,
        nullable=False,
    )
    customer_whatsapp: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        comment="WhatsApp number where the 10-minute edited reel is delivered",
    )
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reel_url: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True,
        comment="Storage URL / WhatsApp media handle of the delivered reel",
    )
    delivered_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    # Payment and Cash on Delivery fields
    payment_method: Mapped[Optional[PaymentMethod]] = mapped_column(
        Enum(PaymentMethod, native_enum=False, length=50, values_callable=lambda x: [e.value for e in x]),
        nullable=True,
        index=True,
    )
    total_amount: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(10, 2),
        nullable=True,
        comment="Calculated server-side from package price",
    )
    advance_amount: Mapped[Decimal] = mapped_column(
        Numeric(10, 2),
        default=Decimal("0.00"),
        nullable=False,
        comment="Amount paid online via Razorpay (full or advance)",
    )
    remaining_amount: Mapped[Decimal] = mapped_column(
        Numeric(10, 2),
        default=Decimal("0.00"),
        nullable=False,
        comment="Remaining balance to collect in cash on delivery",
    )
    payment_status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, name="payment_status", create_type=False, values_callable=lambda x: [e.value for e in x]),
        default=PaymentStatus.PENDING,
        index=True,
        nullable=False,
    )
    cash_collected: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )
    cash_collected_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # Relationships
    customer: Mapped["User"] = relationship(
        "User",
        foreign_keys=[customer_id],
        back_populates="bookings_as_customer",
    )
    creator: Mapped[Optional["User"]] = relationship(
        "User",
        foreign_keys=[creator_id],
        back_populates="bookings_as_creator",
    )
    package: Mapped["Package"] = relationship("Package", back_populates="bookings")
    status_history: Mapped[List["BookingStatusHistory"]] = relationship(
        "BookingStatusHistory",
        back_populates="booking",
        cascade="all, delete-orphan",
        order_by="BookingStatusHistory.created_at",
    )
    payments: Mapped[List["Payment"]] = relationship(
        "Payment",
        back_populates="booking",
    )
    review: Mapped[Optional["Review"]] = relationship(
        "Review",
        back_populates="booking",
        uselist=False,
    )

    __table_args__ = (
        Index("ix_bookings_status_city", "status", "city", "is_deleted"),
        Index("ix_bookings_customer_status", "customer_id", "status"),
        Index("ix_bookings_creator_status", "creator_id", "status"),
    )

    def __repr__(self) -> str:
        return f"<Booking {self.booking_code} [{self.status}] in {self.city}>"


# ==============================================================================
# 5. Booking Status History Model
# ==============================================================================

class BookingStatusHistory(TimeStampedUUIDBase):
    """
    Immutable audit timeline for every booking status transition.
    """
    __tablename__ = "booking_status_history"

    booking_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("bookings.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    status: Mapped[BookingStatus] = mapped_column(
        Enum(BookingStatus, name="booking_status", create_type=False, values_callable=lambda x: [e.value for e in x]),
        nullable=False,
    )
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    changed_by_user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    # Relationships
    booking: Mapped["Booking"] = relationship("Booking", back_populates="status_history")
    changed_by: Mapped[Optional["User"]] = relationship("User", foreign_keys=[changed_by_user_id])

    def __repr__(self) -> str:
        return f"<StatusHistory booking={self.booking_id} status={self.status}>"


# ==============================================================================
# 6. Payment Model
# ==============================================================================

class Payment(TimeStampedUUIDBase):
    """
    Financial transactions for Instant Reel bookings.
    """
    __tablename__ = "payments"

    booking_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("bookings.id", ondelete="RESTRICT"),
        index=True,
        nullable=False,
    )
    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        index=True,
        nullable=False,
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="INR", nullable=False)
    payment_method: Mapped[Optional[PaymentMethod]] = mapped_column(
        Enum(PaymentMethod, native_enum=False, length=50, values_callable=lambda x: [e.value for e in x]),
        default=PaymentMethod.RAZORPAY_FULL,
        nullable=True,
    )
    status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, name="payment_status", create_type=False, values_callable=lambda x: [e.value for e in x]),
        default=PaymentStatus.PENDING,
        index=True,
        nullable=False,
    )
    provider: Mapped[str] = mapped_column(
        String(50),
        default="razorpay",
        nullable=False,
        comment="razorpay, upi, or cash_on_delivery",
    )
    transaction_id: Mapped[Optional[str]] = mapped_column(
        String(255),
        unique=True,
        index=True,
        nullable=True,
    )
    razorpay_order_id: Mapped[Optional[str]] = mapped_column(
        String(255),
        index=True,
        nullable=True,
    )
    razorpay_payment_id: Mapped[Optional[str]] = mapped_column(
        String(255),
        unique=True,
        index=True,
        nullable=True,
    )
    razorpay_signature: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True,
    )
    failure_reason: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )
    paid_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # Relationships
    booking: Mapped["Booking"] = relationship("Booking", back_populates="payments")
    customer: Mapped["User"] = relationship("User", back_populates="payments")

    __table_args__ = (
        Index("ix_payments_booking_status", "booking_id", "status"),
        Index("ix_payments_razorpay_order_id", "razorpay_order_id"),
        Index("ix_payments_razorpay_payment_id", "razorpay_payment_id"),
    )

    def __repr__(self) -> str:
        return f"<Payment Rs.{self.amount} [{self.status}] txn={self.transaction_id}>"


# ==============================================================================
# 7. Review Model
# ==============================================================================

class Review(TimeStampedUUIDBase):
    """
    Customer ratings & reviews for reel creators.
    """
    __tablename__ = "reviews"

    booking_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("bookings.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )
    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        index=True,
        nullable=False,
    )
    creator_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        index=True,
        nullable=False,
    )
    rating: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        comment="Overall rating from 1 to 5",
    )
    comment: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    turnaround_speed_rating: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True,
        comment="Rating for 10-minute delivery promise (1-5)",
    )
    video_quality_rating: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True,
        comment="Rating for camera and editing quality (1-5)",
    )

    # Relationships
    booking: Mapped["Booking"] = relationship("Booking", back_populates="review")
    customer: Mapped["User"] = relationship(
        "User",
        foreign_keys=[customer_id],
        back_populates="reviews_given",
    )
    creator: Mapped["User"] = relationship(
        "User",
        foreign_keys=[creator_id],
        back_populates="reviews_received",
    )

    __table_args__ = (
        Index("ix_reviews_creator_rating", "creator_id", "rating"),
    )

    def __repr__(self) -> str:
        return f"<Review booking={self.booking_id} rating={self.rating}>"


# ==============================================================================
# 8. Notification Model
# ==============================================================================

class Notification(TimeStampedUUIDBase):
    """
    Push & in-app alerts for booking status updates, assignments, and reel delivery.
    """
    __tablename__ = "notifications"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    title: Mapped[str] = mapped_column(String(150), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    type: Mapped[str] = mapped_column(
        String(50),
        index=True,
        nullable=False,
        comment="booking_assigned, creator_arrived, reel_delivered, payment_received",
    )
    data: Mapped[Optional[dict]] = mapped_column(
        JSONB,
        nullable=True,
        comment="Metadata payload, e.g. {'booking_id': '...'}",
    )
    is_read: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        index=True,
        nullable=False,
    )
    read_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="notifications")

    __table_args__ = (
        Index("ix_notifications_user_read_created", "user_id", "is_read", "created_at"),
    )

    def __repr__(self) -> str:
        return f"<Notification user={self.user_id} title='{self.title}'>"


# ==============================================================================
# OTP & Refresh Token Models (Auth Support)
# ==============================================================================

class OTPVerification(TimeStampedUUIDBase):
    """Stores 6-digit OTP codes with 5-minute expiry."""
    __tablename__ = "otp_verifications"

    mobile: Mapped[str] = mapped_column(String(20), index=True, nullable=False)
    otp_code: Mapped[str] = mapped_column(String(6), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    __table_args__ = (
        Index("ix_otp_mobile_used", "mobile", "is_used"),
    )

    def is_valid(self) -> bool:
        now = datetime.now(timezone.utc)
        return not self.is_used and self.expires_at > now


class RefreshToken(TimeStampedUUIDBase):
    """Stores issued refresh tokens for revocation and rotation."""
    __tablename__ = "refresh_tokens"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    token_hash: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        index=True,
        nullable=False,
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_revoked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="refresh_tokens")

    def is_valid(self) -> bool:
        now = datetime.now(timezone.utc)
        return not self.is_revoked and self.expires_at > now


# ==============================================================================
# 9. Payment Configuration Model (COD Settings)
# ==============================================================================

class PaymentConfig(TimeStampedUUIDBase):
    """
    Global payment & Cash On Delivery configuration.
    """
    __tablename__ = "payment_configs"

    cod_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    cod_minimum_advance: Mapped[Decimal] = mapped_column(
        Numeric(10, 2),
        default=Decimal("100.00"),
        nullable=False,
        comment="Mandatory online advance required for COD bookings",
    )

    def __repr__(self) -> str:
        return f"<PaymentConfig cod_enabled={self.cod_enabled} min_advance=Rs.{self.cod_minimum_advance}>"

