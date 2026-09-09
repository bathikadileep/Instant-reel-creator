import uuid
from datetime import datetime, time, timezone
from decimal import Decimal
from typing import List, Optional

from sqlalchemy import and_, func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import NotFoundException
from app.models.schema_models import (
    Booking,
    BookingStatus,
    CreatorProfile,
    Package,
    Payment,
    PaymentStatus,
    Review,
    User,
    UserRole,
)
from app.models.user import OTPVerification
from app.schemas.admin import (
    AdminCreatorItem,
    AdminCustomerItem,
    AdminDashboardMetrics,
    AdminRevenueReport,
    AdminSeedResponse,
    CityMetricItem,
    RecentTransactionItem,
    RevenueCityBreakdown,
    RevenuePackageBreakdown,
)

TARGET_CITIES = ["Maripeda", "Mahabubabad", "Khammam", "Warangal"]

ACTIVE_STATUSES = [
    BookingStatus.PENDING,
    BookingStatus.ASSIGNED,
    BookingStatus.ON_THE_WAY,
    BookingStatus.REACHED,
    BookingStatus.SHOOTING_STARTED,
    BookingStatus.SHOOTING_COMPLETED,
    BookingStatus.EDITING_STARTED,
    BookingStatus.EDITING_COMPLETED,
    BookingStatus.CREATOR_ASSIGNED,
    BookingStatus.ARRIVED_AT_LOCATION,
    BookingStatus.SHOOTING_IN_PROGRESS,
    BookingStatus.EDITING,
]

COMPLETED_STATUSES = [
    BookingStatus.DELIVERED,
    BookingStatus.COMPLETED,
    BookingStatus.DELIVERED_ON_WHATSAPP,
]


class AdminService:
    @staticmethod
    async def get_dashboard_metrics(db: AsyncSession) -> AdminDashboardMetrics:
        """Aggregate platform KPIs for the Admin Dashboard."""
        # Bookings counts
        total_b = await db.scalar(
            select(func.count(Booking.id)).where(Booking.is_deleted == False)
        ) or 0

        active_b = await db.scalar(
            select(func.count(Booking.id)).where(
                and_(Booking.is_deleted == False, Booking.status.in_(ACTIVE_STATUSES))
            )
        ) or 0

        completed_b = await db.scalar(
            select(func.count(Booking.id)).where(
                and_(Booking.is_deleted == False, Booking.status.in_(COMPLETED_STATUSES))
            )
        ) or 0

        cancelled_b = await db.scalar(
            select(func.count(Booking.id)).where(
                and_(Booking.is_deleted == False, Booking.status == BookingStatus.CANCELLED)
            )
        ) or 0

        # Creators counts
        total_c = await db.scalar(
            select(func.count(User.id)).where(
                and_(User.is_deleted == False, User.role == UserRole.CREATOR)
            )
        ) or 0

        online_c = await db.scalar(
            select(func.count(CreatorProfile.id)).where(
                and_(CreatorProfile.is_deleted == False, CreatorProfile.is_available == True)
            )
        ) or 0

        # Customers counts
        total_cust = await db.scalar(
            select(func.count(User.id)).where(
                and_(User.is_deleted == False, User.role == UserRole.CUSTOMER)
            )
        ) or 0

        # Revenue calculations from completed/delivered bookings with package prices
        rev_query = (
            select(func.coalesce(func.sum(Package.price), 0))
            .select_from(Booking)
            .join(Package, Booking.package_id == Package.id)
            .where(
                and_(
                    Booking.is_deleted == False,
                    Booking.status.in_(COMPLETED_STATUSES),
                )
            )
        )
        total_rev_val = await db.scalar(rev_query) or 0.0

        # Today's Revenue
        now = datetime.now(timezone.utc)
        today_start = datetime.combine(now.date(), time.min, tzinfo=timezone.utc)
        today_rev_query = (
            select(func.coalesce(func.sum(Package.price), 0))
            .select_from(Booking)
            .join(Package, Booking.package_id == Package.id)
            .where(
                and_(
                    Booking.is_deleted == False,
                    Booking.status.in_(COMPLETED_STATUSES),
                    Booking.created_at >= today_start,
                )
            )
        )
        today_rev_val = await db.scalar(today_rev_query) or 0.0

        # City metrics
        city_items: List[CityMetricItem] = []
        for city in TARGET_CITIES:
            c_bookings = await db.scalar(
                select(func.count(Booking.id)).where(
                    and_(Booking.is_deleted == False, Booking.city.ilike(f"%{city}%"))
                )
            ) or 0

            c_rev = await db.scalar(
                select(func.coalesce(func.sum(Package.price), 0))
                .select_from(Booking)
                .join(Package, Booking.package_id == Package.id)
                .where(
                    and_(
                        Booking.is_deleted == False,
                        Booking.city.ilike(f"%{city}%"),
                        Booking.status.in_(COMPLETED_STATUSES),
                    )
                )
            ) or 0.0

            c_creators = await db.scalar(
                select(func.count(CreatorProfile.id)).where(
                    and_(
                        CreatorProfile.is_deleted == False,
                        CreatorProfile.primary_city.ilike(f"%{city}%"),
                    )
                )
            ) or 0

            city_items.append(
                CityMetricItem(
                    city=city,
                    bookings_count=c_bookings,
                    gross_revenue=float(c_rev),
                    creators_count=c_creators,
                )
            )

        return AdminDashboardMetrics(
            total_bookings=total_b,
            active_bookings=active_b,
            completed_bookings=completed_b,
            cancelled_bookings=cancelled_b,
            total_revenue=float(total_rev_val),
            today_revenue=float(today_rev_val),
            total_creators=total_c,
            online_creators=online_c,
            total_customers=total_cust,
            city_metrics=city_items,
        )

    @staticmethod
    async def get_creators(
        db: AsyncSession,
        city: Optional[str] = None,
        is_available: Optional[bool] = None,
        is_verified: Optional[bool] = None,
        search: Optional[str] = None,
    ) -> List[AdminCreatorItem]:
        """Fetch all creators with filtering."""
        query = (
            select(CreatorProfile)
            .join(User, CreatorProfile.user_id == User.id)
            .options(selectinload(CreatorProfile.user))
            .where(CreatorProfile.is_deleted == False)
            .order_by(CreatorProfile.created_at.desc())
        )

        if city and city.lower() != "all":
            query = query.where(CreatorProfile.primary_city.ilike(f"%{city}%"))

        if is_available is not None:
            query = query.where(CreatorProfile.is_available == is_available)

        if is_verified is True:
            query = query.where(CreatorProfile.verified_at.is_not(None))
        elif is_verified is False:
            query = query.where(CreatorProfile.verified_at.is_(None))

        if search and search.strip():
            s = f"%{search.strip()}%"
            query = query.where(
                or_(
                    User.name.ilike(s),
                    User.mobile.ilike(s),
                    CreatorProfile.camera_gear.ilike(s),
                )
            )

        result = await db.execute(query)
        profiles = result.scalars().all()

        items = []
        for p in profiles:
            items.append(
                AdminCreatorItem(
                    id=p.id,
                    user_id=p.user_id,
                    name=p.user.name or "Unnamed Creator",
                    mobile=p.user.mobile,
                    email=p.user.email,
                    primary_city=p.primary_city,
                    service_areas=p.service_areas or [],
                    camera_gear=p.camera_gear,
                    whatsapp_number=p.whatsapp_number,
                    rating_avg=float(p.rating_avg),
                    total_reels_delivered=p.total_reels_delivered,
                    is_available=p.is_available,
                    is_verified=p.verified_at is not None,
                    verified_at=p.verified_at,
                    created_at=p.created_at,
                )
            )
        return items

    @staticmethod
    async def toggle_creator_verification(
        db: AsyncSession, creator_profile_id: uuid.UUID
    ) -> AdminCreatorItem:
        """Toggle verification status of a creator."""
        result = await db.execute(
            select(CreatorProfile)
            .options(selectinload(CreatorProfile.user))
            .where(CreatorProfile.id == creator_profile_id)
        )
        profile = result.scalar_one_or_none()
        if not profile:
            raise NotFoundException("Creator profile not found")

        if profile.verified_at is None:
            profile.verified_at = datetime.now(timezone.utc)
        else:
            profile.verified_at = None

        await db.commit()
        await db.refresh(profile)

        return AdminCreatorItem(
            id=profile.id,
            user_id=profile.user_id,
            name=profile.user.name or "Unnamed Creator",
            mobile=profile.user.mobile,
            email=profile.user.email,
            primary_city=profile.primary_city,
            service_areas=profile.service_areas or [],
            camera_gear=profile.camera_gear,
            whatsapp_number=profile.whatsapp_number,
            rating_avg=float(profile.rating_avg),
            total_reels_delivered=profile.total_reels_delivered,
            is_available=profile.is_available,
            is_verified=profile.verified_at is not None,
            verified_at=profile.verified_at,
            created_at=profile.created_at,
        )

    @staticmethod
    async def toggle_creator_availability(
        db: AsyncSession, creator_profile_id: uuid.UUID
    ) -> AdminCreatorItem:
        """Toggle online/offline status of a creator."""
        result = await db.execute(
            select(CreatorProfile)
            .options(selectinload(CreatorProfile.user))
            .where(CreatorProfile.id == creator_profile_id)
        )
        profile = result.scalar_one_or_none()
        if not profile:
            raise NotFoundException("Creator profile not found")

        profile.is_available = not profile.is_available
        await db.commit()
        await db.refresh(profile)

        return AdminCreatorItem(
            id=profile.id,
            user_id=profile.user_id,
            name=profile.user.name or "Unnamed Creator",
            mobile=profile.user.mobile,
            email=profile.user.email,
            primary_city=profile.primary_city,
            service_areas=profile.service_areas or [],
            camera_gear=profile.camera_gear,
            whatsapp_number=profile.whatsapp_number,
            rating_avg=float(profile.rating_avg),
            total_reels_delivered=profile.total_reels_delivered,
            is_available=profile.is_available,
            is_verified=profile.verified_at is not None,
            verified_at=profile.verified_at,
            created_at=profile.created_at,
        )

    @staticmethod
    async def get_customers(
        db: AsyncSession,
        search: Optional[str] = None,
        is_active: Optional[bool] = None,
    ) -> List[AdminCustomerItem]:
        """Fetch customer directory with spend and booking stats."""
        query = (
            select(User)
            .where(and_(User.is_deleted == False, User.role == UserRole.CUSTOMER))
            .order_by(User.created_at.desc())
        )

        if is_active is not None:
            query = query.where(User.is_active == is_active)

        if search and search.strip():
            s = f"%{search.strip()}%"
            query = query.where(or_(User.name.ilike(s), User.mobile.ilike(s), User.email.ilike(s)))

        result = await db.execute(query)
        users = result.scalars().all()

        items = []
        for u in users:
            b_count = await db.scalar(
                select(func.count(Booking.id)).where(
                    and_(Booking.is_deleted == False, Booking.customer_id == u.id)
                )
            ) or 0

            total_spent = await db.scalar(
                select(func.coalesce(func.sum(Package.price), 0))
                .select_from(Booking)
                .join(Package, Booking.package_id == Package.id)
                .where(
                    and_(
                        Booking.is_deleted == False,
                        Booking.customer_id == u.id,
                        Booking.status.in_(COMPLETED_STATUSES),
                    )
                )
            ) or 0.0

            items.append(
                AdminCustomerItem(
                    id=u.id,
                    name=u.name,
                    mobile=u.mobile,
                    email=u.email,
                    is_active=u.is_active,
                    total_bookings=b_count,
                    total_spent=float(total_spent),
                    created_at=u.created_at,
                )
            )
        return items

    @staticmethod
    async def toggle_customer_status(
        db: AsyncSession, user_id: uuid.UUID
    ) -> AdminCustomerItem:
        """Toggle active / deactivated status of a customer."""
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise NotFoundException("Customer not found")

        user.is_active = not user.is_active
        await db.commit()
        await db.refresh(user)

        b_count = await db.scalar(
            select(func.count(Booking.id)).where(
                and_(Booking.is_deleted == False, Booking.customer_id == user.id)
            )
        ) or 0

        total_spent = await db.scalar(
            select(func.coalesce(func.sum(Package.price), 0))
            .select_from(Booking)
            .join(Package, Booking.package_id == Package.id)
            .where(
                and_(
                    Booking.is_deleted == False,
                    Booking.customer_id == user.id,
                    Booking.status.in_(COMPLETED_STATUSES),
                )
            )
        ) or 0.0

        return AdminCustomerItem(
            id=user.id,
            name=user.name,
            mobile=user.mobile,
            email=user.email,
            is_active=user.is_active,
            total_bookings=b_count,
            total_spent=float(total_spent),
            created_at=user.created_at,
        )

    @staticmethod
    async def get_revenue_report(db: AsyncSession) -> AdminRevenueReport:
        """Generate comprehensive revenue analytics and financial breakdowns."""
        # Total Gross
        total_gross = await db.scalar(
            select(func.coalesce(func.sum(Package.price), 0))
            .select_from(Booking)
            .join(Package, Booking.package_id == Package.id)
            .where(
                and_(
                    Booking.is_deleted == False,
                    Booking.status.in_(COMPLETED_STATUSES),
                )
            )
        ) or 0.0

        completed_count = await db.scalar(
            select(func.count(Booking.id)).where(
                and_(
                    Booking.is_deleted == False,
                    Booking.status.in_(COMPLETED_STATUSES),
                )
            )
        ) or 0

        gross_f = float(total_gross)
        creator_payouts_f = round(gross_f * 0.80, 2)
        net_fee_f = round(gross_f * 0.20, 2)
        aov_f = round(gross_f / completed_count, 2) if completed_count > 0 else 0.0

        # By City Breakdown
        by_city: List[RevenueCityBreakdown] = []
        for city in TARGET_CITIES:
            c_count = await db.scalar(
                select(func.count(Booking.id)).where(
                    and_(
                        Booking.is_deleted == False,
                        Booking.city.ilike(f"%{city}%"),
                        Booking.status.in_(COMPLETED_STATUSES),
                    )
                )
            ) or 0

            c_gross = await db.scalar(
                select(func.coalesce(func.sum(Package.price), 0))
                .select_from(Booking)
                .join(Package, Booking.package_id == Package.id)
                .where(
                    and_(
                        Booking.is_deleted == False,
                        Booking.city.ilike(f"%{city}%"),
                        Booking.status.in_(COMPLETED_STATUSES),
                    )
                )
            ) or 0.0

            c_gross_f = float(c_gross)
            by_city.append(
                RevenueCityBreakdown(
                    city=city,
                    bookings_count=c_count,
                    gross_revenue=c_gross_f,
                    creator_payouts=round(c_gross_f * 0.80, 2),
                    net_platform_fee=round(c_gross_f * 0.20, 2),
                )
            )

        # By Package Breakdown
        packages_res = await db.execute(select(Package).where(Package.is_deleted == False))
        packages = packages_res.scalars().all()
        by_package: List[RevenuePackageBreakdown] = []
        for pkg in packages:
            p_count = await db.scalar(
                select(func.count(Booking.id)).where(
                    and_(
                        Booking.is_deleted == False,
                        Booking.package_id == pkg.id,
                        Booking.status.in_(COMPLETED_STATUSES),
                    )
                )
            ) or 0

            p_gross = float(pkg.price) * p_count
            by_package.append(
                RevenuePackageBreakdown(
                    package_name=pkg.name,
                    bookings_count=p_count,
                    gross_revenue=p_gross,
                )
            )

        # Recent Transactions
        rec_query = (
            select(Booking)
            .options(selectinload(Booking.customer), selectinload(Booking.package))
            .where(
                and_(
                    Booking.is_deleted == False,
                    Booking.status.in_(COMPLETED_STATUSES),
                )
            )
            .order_by(Booking.updated_at.desc())
            .limit(10)
        )
        rec_res = await db.execute(rec_query)
        recent_bookings = rec_res.scalars().all()

        recent_txs: List[RecentTransactionItem] = []
        for b in recent_bookings:
            recent_txs.append(
                RecentTransactionItem(
                    id=b.id,
                    booking_code=b.booking_code,
                    customer_name=b.customer.name if b.customer else "Customer",
                    city=b.city,
                    package_name=b.package.name if b.package else "Standard Package",
                    amount=float(b.package.price) if b.package else 999.0,
                    status="completed",
                    created_at=b.delivered_at or b.updated_at,
                )
            )

        return AdminRevenueReport(
            total_gross_revenue=gross_f,
            creator_payouts=creator_payouts_f,
            net_platform_revenue=net_fee_f,
            average_order_value=aov_f,
            total_paid_bookings=completed_count,
            by_city=by_city,
            by_package=by_package,
            recent_transactions=recent_txs,
        )

    @staticmethod
    async def seed_super_admin(db: AsyncSession) -> AdminSeedResponse:
        """Seed or ensure Super Admin user exists in Neon DB."""
        admin_mobile = "+919876543210"
        admin_email = "admin@instantreel.in"

        res = await db.execute(select(User).where(User.mobile == admin_mobile))
        admin_user = res.scalar_one_or_none()

        if not admin_user:
            admin_user = User(
                mobile=admin_mobile,
                email=admin_email,
                name="Super Admin",
                role=UserRole.ADMIN,
                is_active=True,
            )
            db.add(admin_user)
            await db.flush()
        else:
            admin_user.role = UserRole.ADMIN
            admin_user.is_active = True
            admin_user.name = "Super Admin"

        # Ensure valid dev OTP code is active for 1 year
        dev_otp = "123456"
        await db.execute(
            update(OTPVerification)
            .where(OTPVerification.mobile == admin_mobile)
            .values(is_used=True)
        )
        otp_rec = OTPVerification(
            mobile=admin_mobile,
            otp_code=dev_otp,
            expires_at=datetime(2027, 12, 31, tzinfo=timezone.utc),
            is_used=False,
        )
        db.add(otp_rec)
        await db.commit()

        return AdminSeedResponse(
            success=True,
            message="Super Admin account verified and ready for Admin Panel login.",
            admin_mobile=admin_mobile,
            admin_name="Super Admin",
            dev_otp=dev_otp,
        )
