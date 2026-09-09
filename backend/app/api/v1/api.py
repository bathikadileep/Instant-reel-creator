from fastapi import APIRouter
from app.api.v1.endpoints import auth, bookings, creator, health, packages

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

