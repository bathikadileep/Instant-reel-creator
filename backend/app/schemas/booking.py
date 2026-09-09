import enum
import re
import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any, List, Optional
from pydantic import BaseModel, Field, field_validator

from app.models.schema_models import BookingStatus


class EventType(str, enum.Enum):
    BIRTHDAY = "birthday"
    WEDDING = "wedding"
    SHOP_PROMOTION = "shop_promotion"
    RESTAURANT = "restaurant"
    REAL_ESTATE = "real_estate"
    PERSONAL_BRANDING = "personal_branding"

    @property
    def display_name(self) -> str:
        names = {
            "birthday": "Birthday",
            "wedding": "Wedding",
            "shop_promotion": "Shop Promotion",
            "restaurant": "Restaurant",
            "real_estate": "Real Estate",
            "personal_branding": "Personal Branding",
        }
        return names.get(self.value, self.value)


class PackageResponse(BaseModel):
    id: uuid.UUID
    name: str
    description: str
    price: Decimal
    reels_count: int
    shoot_duration_minutes: int
    delivery_time_minutes: int
    features: List[str]
    is_active: bool

    class Config:
        from_attributes = True


class BookingCreateRequest(BaseModel):
    event_type: EventType = Field(..., example=EventType.SHOP_PROMOTION)
    package_id: uuid.UUID
    city: str = Field(..., example="Khammam")
    location_address: str = Field(..., min_length=5, example="Main Road, Near Clock Tower, Khammam")
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None
    scheduled_at: datetime
    customer_whatsapp: str = Field(..., example="+919876543210")
    notes: Optional[str] = Field(default=None, example="Special focus on food dishes and kitchen B-roll")

    @field_validator("city")
    @classmethod
    def validate_city(cls, v: str) -> str:
        valid_cities = ["maripeda", "mahabubabad", "khammam", "warangal"]
        if v.strip().lower() not in valid_cities:
            raise ValueError(f"City '{v}' is not currently served. Operating cities: Maripeda, Mahabubabad, Khammam, Warangal.")
        return v.strip().title()

    @field_validator("customer_whatsapp")
    @classmethod
    def validate_whatsapp(cls, v: str) -> str:
        cleaned = re.sub(r"[\s\-\(\)]", "", v)
        if len(cleaned) == 10 and cleaned.isdigit():
            cleaned = f"+91{cleaned}"
        elif len(cleaned) == 12 and cleaned.startswith("91"):
            cleaned = f"+{cleaned}"
        if not re.match(r"^\+\d{10,15}$", cleaned):
            raise ValueError("Invalid WhatsApp mobile format. Expected +91XXXXXXXXXX")
        return cleaned


class BookingStatusHistoryResponse(BaseModel):
    id: uuid.UUID
    status: BookingStatus
    note: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class CreatorBasicResponse(BaseModel):
    id: uuid.UUID
    name: Optional[str] = None
    mobile: str

    class Config:
        from_attributes = True


class BookingResponse(BaseModel):
    id: uuid.UUID
    booking_code: str
    customer_id: uuid.UUID
    creator_id: Optional[uuid.UUID] = None
    package_id: uuid.UUID
    status: BookingStatus
    city: str
    location_address: str
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None
    scheduled_at: datetime
    customer_whatsapp: str
    notes: Optional[str] = None
    reel_url: Optional[str] = None
    delivered_at: Optional[datetime] = None
    delivery_status: Optional[str] = "pending"
    created_at: datetime
    package: Optional[PackageResponse] = None
    creator: Optional[CreatorBasicResponse] = None
    status_history: List[BookingStatusHistoryResponse] = []

    class Config:
        from_attributes = True


class BookingStatusUpdateRequest(BaseModel):
    status: BookingStatus
    note: Optional[str] = None
    reel_url: Optional[str] = None
