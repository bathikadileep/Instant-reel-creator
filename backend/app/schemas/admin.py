import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class CityMetricItem(BaseModel):
    city: str
    bookings_count: int = 0
    gross_revenue: float = 0.0
    creators_count: int = 0


class AdminDashboardMetrics(BaseModel):
    total_bookings: int = 0
    active_bookings: int = 0
    completed_bookings: int = 0
    cancelled_bookings: int = 0
    total_revenue: float = 0.0
    today_revenue: float = 0.0
    total_creators: int = 0
    online_creators: int = 0
    total_customers: int = 0
    city_metrics: List[CityMetricItem] = Field(default_factory=list)


class AdminCreatorItem(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    name: str
    mobile: str
    email: Optional[str] = None
    primary_city: str
    service_areas: List[str] = Field(default_factory=list)
    camera_gear: Optional[str] = None
    whatsapp_number: str
    rating_avg: float = 5.0
    total_reels_delivered: int = 0
    is_available: bool = True
    is_verified: bool = False
    verified_at: Optional[datetime] = None
    created_at: datetime


class AdminCustomerItem(BaseModel):
    id: uuid.UUID
    name: Optional[str] = None
    mobile: str
    email: Optional[str] = None
    is_active: bool = True
    total_bookings: int = 0
    total_spent: float = 0.0
    created_at: datetime


class RevenueCityBreakdown(BaseModel):
    city: str
    bookings_count: int
    gross_revenue: float
    creator_payouts: float
    net_platform_fee: float


class RevenuePackageBreakdown(BaseModel):
    package_name: str
    bookings_count: int
    gross_revenue: float


class RecentTransactionItem(BaseModel):
    id: uuid.UUID
    booking_code: str
    customer_name: Optional[str] = None
    city: str
    package_name: str
    amount: float
    status: str
    created_at: datetime


class AdminRevenueReport(BaseModel):
    total_gross_revenue: float
    creator_payouts: float
    net_platform_revenue: float
    average_order_value: float
    total_paid_bookings: int
    by_city: List[RevenueCityBreakdown]
    by_package: List[RevenuePackageBreakdown]
    recent_transactions: List[RecentTransactionItem]


class AdminSeedResponse(BaseModel):
    success: bool
    message: str
    admin_mobile: str
    admin_name: str
    dev_otp: str
