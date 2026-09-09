from fastapi import APIRouter
from app.api.v1.endpoints import auth, health

api_router = APIRouter()

# Health & System Checks
api_router.include_router(health.router, tags=["Health & System"])

# Authentication & RBAC
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# Future Business Modules (to be added in subsequent phases):
# api_router.include_router(bookings.router, prefix="/bookings", tags=["Bookings"])
# api_router.include_router(creators.router, prefix="/creators", tags=["Creators"])
# api_router.include_router(reels.router, prefix="/reels", tags=["Reels"])
