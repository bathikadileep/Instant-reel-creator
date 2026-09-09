from fastapi import APIRouter
from app.api.v1.endpoints import admin, auth, bookings, creator, health, notifications, packages, payments

api_router = APIRouter()

# Health & System Checks
api_router.include_router(health.router, tags=["Health & System"])

# Authentication & RBAC
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# Packages & Pricing
api_router.include_router(packages.router, prefix="/packages", tags=["Packages"])

# Customer & Reel Bookings
api_router.include_router(bookings.router, prefix="/bookings", tags=["Bookings"])

# Creator Studio & Shoot Operations
api_router.include_router(creator.router, prefix="/creator", tags=["Creator"])

# Admin Console & Operations
api_router.include_router(admin.router, prefix="/admin", tags=["Admin"])

# Payment Gateway & Cash on Delivery
api_router.include_router(payments.router, prefix="/payments", tags=["Payments"])

# Firebase Cloud Messaging & Notifications
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])

