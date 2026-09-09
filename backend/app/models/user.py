"""Backward compatibility alias for user models."""

from app.models.schema_models import (
    OTPVerification,
    RefreshToken,
    User,
    UserRole,
)

__all__ = ["User", "UserRole", "OTPVerification", "RefreshToken"]
