import uuid
from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from pydantic import BaseModel, Field

from app.models.schema_models import BookingStatus
from app.schemas.booking import BookingResponse


class CreatorDashboardStats(BaseModel):
    today_bookings_count: int = 0
    completed_bookings_count: int = 0
    today_earnings: Decimal = Decimal("0.00")
    total_earnings: Decimal = Decimal("0.00")
    rating_avg: Decimal = Decimal("5.00")
    total_reviews: int = 0
    is_available: bool = True
    primary_city: Optional[str] = None
    today_bookings: List[BookingResponse] = Field(default_factory=list)


class UpdateBookingStatusRequest(BaseModel):
    status: BookingStatus
    note: Optional[str] = Field(None, max_length=500, description="Optional note describing the progress update")
    reel_url: Optional[str] = Field(None, max_length=500, description="URL or cloud drive link to the finished reel (required when marking delivered)")


class RejectBookingRequest(BaseModel):
    reason: Optional[str] = Field(None, max_length=500, description="Reason for declining the booking assignment")


class DeliverBookingRequest(BaseModel):
    reel_url: str = Field(..., max_length=500, description="Cloud / WhatsApp link to the exported reel")
    note: Optional[str] = Field("Reel delivered directly to customer via WhatsApp", max_length=500)


class ToggleAvailabilityRequest(BaseModel):
    is_available: bool
