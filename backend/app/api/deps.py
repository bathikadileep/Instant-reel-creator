import uuid
from typing import Callable, List
from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.exceptions import ForbiddenException, UnauthorizedException
from app.core.security import decode_access_token, oauth2_scheme
from app.models.user import User, UserRole


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Validate access token and return the current user."""
    if not token:
        raise UnauthorizedException("Authentication token is missing")

    payload = decode_access_token(token)
    if not payload or "sub" not in payload:
        raise UnauthorizedException("Invalid or expired authentication token")

    try:
        user_id = uuid.UUID(payload["sub"])
    except (ValueError, TypeError):
        raise UnauthorizedException("Malformed token subject identifier")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if not user:
        raise UnauthorizedException("User associated with this token was not found")

    return user


async def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    """Ensure that the authenticated user account is active."""
    if not current_user.is_active:
        raise ForbiddenException("User account has been deactivated. Please contact support.")
    return current_user


def require_role(*allowed_roles: UserRole) -> Callable:
    """Dependency factory enforcing Role-Based Access Control (RBAC)."""

    async def role_checker(
        current_user: User = Depends(get_current_active_user),
    ) -> User:
        if current_user.role not in allowed_roles:
            raise ForbiddenException(
                f"Access denied. Requires one of roles: {[r.value for r in allowed_roles]}, "
                f"but current role is '{current_user.role.value}'"
            )
        return current_user

    return role_checker


# Role shortcut dependencies
require_admin = require_role(UserRole.ADMIN)
require_creator = require_role(UserRole.CREATOR, UserRole.ADMIN)
require_customer = require_role(UserRole.CUSTOMER, UserRole.ADMIN)
