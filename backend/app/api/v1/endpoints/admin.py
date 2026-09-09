import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_active_user, require_admin
from app.core.database import get_db
from app.models.user import User
from app.schemas.admin import (
    AdminCreatorItem,
    AdminCustomerItem,
    AdminDashboardMetrics,
    AdminRevenueReport,
    AdminSeedResponse,
)
from app.services.admin_service import AdminService

router = APIRouter()


@router.post(
    "/seed",
    response_model=AdminSeedResponse,
    status_code=status.HTTP_200_OK,
    summary="Seed / Ensure Super Admin Account",
    description="Seeds default Super Admin account with mobile +919876543210 and OTP 123456.",
)
async def seed_super_admin(
    db: AsyncSession = Depends(get_db),
) -> AdminSeedResponse:
    return await AdminService.seed_super_admin(db)


@router.get(
    "/dashboard",
    response_model=AdminDashboardMetrics,
    status_code=status.HTTP_200_OK,
    summary="Get Admin Dashboard Metrics",
    description="Retrieves cross-city KPIs, live booking states, online creator counts, and today's revenue.",
)
async def get_admin_dashboard(
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> AdminDashboardMetrics:
    return await AdminService.get_dashboard_metrics(db)


@router.get(
    "/creators",
    response_model=List[AdminCreatorItem],
    status_code=status.HTTP_200_OK,
    summary="List Creators with Admin Metrics",
)
async def list_creators(
    city: Optional[str] = Query(None, description="Filter by city: Maripeda, Mahabubabad, Khammam, Warangal"),
    is_available: Optional[bool] = Query(None, description="Filter by online availability"),
    is_verified: Optional[bool] = Query(None, description="Filter by verified badge"),
    search: Optional[str] = Query(None, description="Search by name, phone or gear"),
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> List[AdminCreatorItem]:
    return await AdminService.get_creators(
        db=db,
        city=city,
        is_available=is_available,
        is_verified=is_verified,
        search=search,
    )


@router.put(
    "/creators/{creator_id}/toggle-verify",
    response_model=AdminCreatorItem,
    status_code=status.HTTP_200_OK,
    summary="Toggle Creator Verification Badge",
)
async def toggle_creator_verification(
    creator_id: uuid.UUID,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> AdminCreatorItem:
    return await AdminService.toggle_creator_verification(db, creator_id)


@router.put(
    "/creators/{creator_id}/toggle-availability",
    response_model=AdminCreatorItem,
    status_code=status.HTTP_200_OK,
    summary="Toggle Creator Online/Offline Status",
)
async def toggle_creator_availability(
    creator_id: uuid.UUID,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> AdminCreatorItem:
    return await AdminService.toggle_creator_availability(db, creator_id)


@router.get(
    "/customers",
    response_model=List[AdminCustomerItem],
    status_code=status.HTTP_200_OK,
    summary="List Customers with Spend and Booking Stats",
)
async def list_customers(
    search: Optional[str] = Query(None, description="Search by name, mobile, or email"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> List[AdminCustomerItem]:
    return await AdminService.get_customers(db=db, search=search, is_active=is_active)


@router.put(
    "/customers/{customer_id}/toggle-active",
    response_model=AdminCustomerItem,
    status_code=status.HTTP_200_OK,
    summary="Toggle Customer Active / Suspended Status",
)
async def toggle_customer_status(
    customer_id: uuid.UUID,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> AdminCustomerItem:
    return await AdminService.toggle_customer_status(db, customer_id)


@router.get(
    "/reports/revenue",
    response_model=AdminRevenueReport,
    status_code=status.HTTP_200_OK,
    summary="Get Financial & Revenue Analytics Report",
)
async def get_revenue_report(
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> AdminRevenueReport:
    return await AdminService.get_revenue_report(db)
