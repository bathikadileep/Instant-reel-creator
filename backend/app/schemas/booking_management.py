import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field

from app.schemas.booking import BookingResponse


class AssignCreatorRequest(BaseModel):
    creator_id: uuid.UUID = Field(..., description="UUID of the creator user to assign")
    note: Optional[str] = Field(None, max_length=500, description="Optional assignment notes or instructions")


class CancelBookingRequest(BaseModel):
    reason: str = Field(
        ...,
        min_length=3,
        max_length=500,
        description="Reason for cancellation (e.g. Weather delay, Client rescheduled, Emergency)",
    )
    note: Optional[str] = Field(None, max_length=500, description="Additional context or internal remarks")


class BookingTimelineItem(BaseModel):
    status: str
    title: str
    note: Optional[str] = None
    changed_by_id: Optional[uuid.UUID] = None
    changed_by_name: Optional[str] = None
    changed_by_role: Optional[str] = None
    timestamp: datetime
    is_current: bool = False
    is_completed: bool = True


class BookingTimelineResponse(BaseModel):
    booking_id: uuid.UUID
    booking_code: str
    current_status: str
    city: str
    location_address: str
    customer_name: Optional[str] = None
    creator_name: Optional[str] = None
    scheduled_at: datetime
    delivered_at: Optional[datetime] = None
    reel_url: Optional[str] = None
    events: List[BookingTimelineItem] = Field(default_factory=list)


class BookingListResponse(BaseModel):
    items: List[BookingResponse]
    total: int
    skip: int
    limit: int
