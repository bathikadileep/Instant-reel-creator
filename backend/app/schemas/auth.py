import re
import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator

from app.models.user import UserRole


class SendOTPRequest(BaseModel):
    """Request payload to send an OTP."""
    mobile: str = Field(
        ...,
        description="Mobile number with country code (e.g. +919876543210 or 9876543210)",
        example="+919876543210",
    )

    @field_validator("mobile")
    @classmethod
    def clean_mobile(cls, v: str) -> str:
        # Strip spaces, hyphens, and brackets
        cleaned = re.sub(r"[\s\-\(\)]", "", v)
        # Normalize 10-digit Indian numbers with +91
        if len(cleaned) == 10 and cleaned.isdigit():
            cleaned = f"+91{cleaned}"
        elif len(cleaned) == 12 and cleaned.startswith("91"):
            cleaned = f"+{cleaned}"
        
        if not re.match(r"^\+\d{10,15}$", cleaned):
            raise ValueError("Invalid mobile number format. Expected format: +91XXXXXXXXXX")
        return cleaned


class SendOTPResponse(BaseModel):
    """Response payload after OTP is dispatched."""
    success: bool = True
    message: str = "OTP sent successfully"
    mobile: str
    dev_otp: Optional[str] = Field(
        default=None,
        description="Provided in development mode for easy testing without SMS gateway.",
    )


class VerifyOTPRequest(BaseModel):
    """Request payload to verify an OTP."""
    mobile: str = Field(..., example="+919876543210")
    otp: str = Field(..., min_length=6, max_length=6, example="123456")

    @field_validator("mobile")
    @classmethod
    def clean_mobile(cls, v: str) -> str:
        cleaned = re.sub(r"[\s\-\(\)]", "", v)
        if len(cleaned) == 10 and cleaned.isdigit():
            cleaned = f"+91{cleaned}"
        elif len(cleaned) == 12 and cleaned.startswith("91"):
            cleaned = f"+{cleaned}"
        return cleaned


class VerifyOTPResponse(BaseModel):
    """Response payload indicating OTP validity."""
    success: bool = True
    message: str = "OTP verified successfully"
    is_new_user: bool = False


class LoginRequest(BaseModel):
    """Request payload to log in or sign up via mobile OTP."""
    mobile: str = Field(..., example="+919876543210")
    otp: str = Field(..., min_length=6, max_length=6, example="123456")
    role: Optional[UserRole] = Field(
        default=UserRole.CUSTOMER,
        description="Role if registering for the first time.",
    )
    name: Optional[str] = Field(default=None, max_length=100, example="John Doe")

    @field_validator("mobile")
    @classmethod
    def clean_mobile(cls, v: str) -> str:
        cleaned = re.sub(r"[\s\-\(\)]", "", v)
        if len(cleaned) == 10 and cleaned.isdigit():
            cleaned = f"+91{cleaned}"
        elif len(cleaned) == 12 and cleaned.startswith("91"):
            cleaned = f"+{cleaned}"
        return cleaned


class UserRead(BaseModel):
    """Public user profile schema."""
    id: uuid.UUID
    name: Optional[str] = None
    mobile: str
    role: UserRole
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    """Access & refresh token response."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserRead


class RefreshTokenRequest(BaseModel):
    """Request payload to rotate access token using a refresh token."""
    refresh_token: str = Field(..., description="Active refresh token string")


class UpdateRoleRequest(BaseModel):
    """Request payload to select or switch user role."""
    role: UserRole = Field(..., example=UserRole.CREATOR)
