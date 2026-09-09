import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field, computed_field, model_validator


class DeviceTokenRegisterRequest(BaseModel):
    fcm_token: str = Field(..., min_length=10, max_length=512, description="FCM Registration Token")
    platform: str = Field(default="android", description="Device platform: android, ios, web")
    device_type: Optional[str] = Field(default=None, description="Alias for platform")
    device_name: Optional[str] = Field(default=None, max_length=100, description="Device model or browser name")

    @model_validator(mode="before")
    @classmethod
    def resolve_platform(cls, data: Any) -> Any:
        if isinstance(data, dict):
            if "device_type" in data and ("platform" not in data or data["platform"] == "android"):
                data["platform"] = data["device_type"]
        return data


class DeviceTokenResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    fcm_token: str
    platform: str
    device_name: Optional[str] = None
    is_active: bool
    created_at: datetime

    @computed_field
    @property
    def device_type(self) -> str:
        return self.platform

    model_config = ConfigDict(from_attributes=True)


class NotificationResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    body: str
    type: str
    data: Optional[Dict[str, Any]] = None
    is_read: bool
    read_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class NotificationListResponse(BaseModel):
    items: List[NotificationResponse]
    total: int
    unread_count: int


class UnreadCountResponse(BaseModel):
    unread_count: int


class SendNotificationRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=150)
    body: str = Field(..., min_length=1, max_length=1000)
    type: str = Field(default="system", max_length=50)
    data: Optional[Dict[str, Any]] = None
