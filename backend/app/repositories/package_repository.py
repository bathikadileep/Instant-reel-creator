from decimal import Decimal
from typing import List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.schema_models import Package
from app.repositories.base import BaseRepository


class PackageRepository(BaseRepository[Package]):
    def __init__(self, db: AsyncSession):
        super().__init__(Package, db)

    async def get_active_packages(self) -> List[Package]:
        """Fetch all active instant reel packages ordered by price."""
        query = (
            select(Package)
            .where(
                Package.is_active == True,  # noqa: E712
                Package.is_deleted == False,  # noqa: E712
            )
            .order_by(Package.price.asc())
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def seed_default_packages_if_empty(self) -> List[Package]:
        """Seed starter packages if the table is empty."""
        active = await self.get_active_packages()
        if active:
            return active

        defaults = [
            Package(
                name="Instant 10-Min Reel",
                description="Fast on-demand shoot at your location with rapid 10-minute on-site editing and instant WhatsApp delivery.",
                price=Decimal("499.00"),
                reels_count=1,
                shoot_duration_minutes=20,
                delivery_time_minutes=10,
                features=[
                    "1 High-Resolution 9:16 Vertical Reel",
                    "Professional Camera & Gimbal Shoot",
                    "10-Minute Rapid Edit on Location",
                    "Color Grading & Trending Audio",
                    "Direct HD Delivery via WhatsApp",
                ],
                is_active=True,
            ),
            Package(
                name="Pro Duo Spotlight",
                description="2 cinematic vertical reels for businesses, restaurants, or personal branding with hooks and call-to-action.",
                price=Decimal("899.00"),
                reels_count=2,
                shoot_duration_minutes=45,
                delivery_time_minutes=15,
                features=[
                    "2 High-Definition 9:16 Vertical Reels",
                    "Dedicated Storyboard & Hook Guidance",
                    "Wireless Lapel Mic Audio Recording",
                    "Dynamic Hormozi-style Captions",
                    "Delivered Directly to WhatsApp",
                ],
                is_active=True,
            ),
            Package(
                name="Event / Store Mega Pack",
                description="Comprehensive 4-reel shoot ideal for store launches, weddings, birthdays, or product showcases.",
                price=Decimal("1599.00"),
                reels_count=4,
                shoot_duration_minutes=90,
                delivery_time_minutes=30,
                features=[
                    "4 Cinematic Vertical Reels",
                    "Drone / High-Angle B-Roll (Subject to Gear)",
                    "Complete On-Site Event Coverage",
                    "Multiple Aspect Ratio Exports",
                    "Priority WhatsApp Transfer",
                ],
                is_active=True,
            ),
        ]

        for pkg in defaults:
            self.db.add(pkg)
        await self.db.commit()

        return await self.get_active_packages()
