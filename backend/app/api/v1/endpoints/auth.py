import logging
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_active_user
from app.core.config import settings
from app.core.database import get_db
from app.core.exceptions import AppException, NotFoundException, UnauthorizedException
from app.core.security import (
    create_access_token,
    create_refresh_token,
    generate_otp,
    hash_token,
)
from app.models.user import OTPVerification, RefreshToken, User, UserRole
from app.schemas.auth import (
    LoginRequest,
    RefreshTokenRequest,
    SendOTPRequest,
    SendOTPResponse,
    TokenResponse,
    UpdateRoleRequest,
    UserRead,
    VerifyOTPRequest,
    VerifyOTPResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post(
    "/send_otp",
    response_model=SendOTPResponse,
    status_code=status.HTTP_200_OK,
    summary="Send Mobile OTP",
    description="Generates a 6-digit OTP with a 5-minute validity period for mobile verification.",
)
async def send_otp(
    payload: SendOTPRequest,
    db: AsyncSession = Depends(get_db),
) -> SendOTPResponse:
    # Invalidate previous unused OTPs for this mobile
    await db.execute(
        update(OTPVerification)
        .where(
            OTPVerification.mobile == payload.mobile,
            OTPVerification.is_used == False,  # noqa: E712
        )
        .values(is_used=True)
    )

    # Generate 6-digit OTP (use "123456" in debug mode if desired, or random)
    code = generate_otp(is_dev=settings.DEBUG)
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=5)

    otp_record = OTPVerification(
        mobile=payload.mobile,
        otp_code=code,
        expires_at=expires_at,
        is_used=False,
    )
    db.add(otp_record)
    await db.commit()

    logger.info(f"OTP generated for mobile {payload.mobile}: {code if settings.DEBUG else '******'}")

    return SendOTPResponse(
        success=True,
        message="OTP sent successfully to your mobile number",
        mobile=payload.mobile,
        dev_otp=code if settings.DEBUG else None,
    )


@router.post(
    "/verify_otp",
    response_model=VerifyOTPResponse,
    status_code=status.HTTP_200_OK,
    summary="Verify OTP",
    description="Verifies an entered OTP without issuing final login session tokens.",
)
async def verify_otp(
    payload: VerifyOTPRequest,
    db: AsyncSession = Depends(get_db),
) -> VerifyOTPResponse:
    result = await db.execute(
        select(OTPVerification)
        .where(
            OTPVerification.mobile == payload.mobile,
            OTPVerification.otp_code == payload.otp,
            OTPVerification.is_used == False,  # noqa: E712
        )
        .order_by(OTPVerification.created_at.desc())
    )
    otp_record = result.scalars().first()

    if not otp_record or not otp_record.is_valid():
        raise AppException(
            message="Invalid or expired OTP code. Please request a new one.",
            status_code=status.HTTP_400_BAD_REQUEST,
            code="INVALID_OTP",
        )

    # Check if user already exists
    user_result = await db.execute(
        select(User).where(User.mobile == payload.mobile)
    )
    user_exists = user_result.scalar_one_or_none() is not None

    return VerifyOTPResponse(
        success=True,
        message="OTP verified successfully",
        is_new_user=not user_exists,
    )


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Login or Register with Mobile OTP",
    description="Validates the OTP, creates user record if new, and issues JWT access and refresh tokens.",
)
async def login(
    payload: LoginRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    # Validate OTP
    result = await db.execute(
        select(OTPVerification)
        .where(
            OTPVerification.mobile == payload.mobile,
            OTPVerification.otp_code == payload.otp,
            OTPVerification.is_used == False,  # noqa: E712
        )
        .order_by(OTPVerification.created_at.desc())
    )
    otp_record = result.scalars().first()

    if not otp_record or not otp_record.is_valid():
        raise AppException(
            message="Invalid or expired OTP code. Please request a new code.",
            status_code=status.HTTP_400_BAD_REQUEST,
            code="INVALID_OTP",
        )

    # Mark OTP as consumed
    otp_record.is_used = True

    # Find or create User
    user_query = await db.execute(
        select(User).where(User.mobile == payload.mobile)
    )
    user = user_query.scalar_one_or_none()

    if not user:
        user = User(
            mobile=payload.mobile,
            name=payload.name,
            role=payload.role or UserRole.CUSTOMER,
            is_active=True,
        )
        db.add(user)
        await db.flush()  # Flush to populate user.id
    elif not user.is_active:
        raise AppException(
            message="Account is deactivated. Please contact support.",
            status_code=status.HTTP_403_FORBIDDEN,
            code="ACCOUNT_DEACTIVATED",
        )

    # Generate JWT Access Token
    access_token = create_access_token(
        subject=user.id,
        role=user.role.value,
    )

    # Generate Refresh Token
    raw_refresh_token, refresh_expiry = create_refresh_token(subject=user.id)
    hashed_token = hash_token(raw_refresh_token)

    refresh_record = RefreshToken(
        user_id=user.id,
        token_hash=hashed_token,
        expires_at=refresh_expiry,
        is_revoked=False,
    )
    db.add(refresh_record)
    await db.commit()
    await db.refresh(user)

    return TokenResponse(
        access_token=access_token,
        refresh_token=raw_refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserRead.model_validate(user),
    )


@router.post(
    "/refresh_token",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Refresh Access Token",
    description="Validates a refresh token, rotates it, and issues a fresh JWT access token.",
)
async def refresh_token(
    payload: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    hashed = hash_token(payload.refresh_token)
    result = await db.execute(
        select(RefreshToken).where(RefreshToken.token_hash == hashed)
    )
    token_record = result.scalar_one_or_none()

    if not token_record or not token_record.is_valid():
        raise UnauthorizedException("Invalid, expired, or revoked refresh token")

    # Fetch associated user
    user_result = await db.execute(
        select(User).where(User.id == token_record.user_id)
    )
    user = user_result.scalar_one_or_none()

    if not user or not user.is_active:
        raise UnauthorizedException("User associated with this token is inactive or deleted")

    # Revoke old refresh token (Token Rotation Security)
    token_record.is_revoked = True

    # Generate fresh tokens
    new_access_token = create_access_token(
        subject=user.id,
        role=user.role.value,
    )
    new_raw_refresh, new_refresh_expiry = create_refresh_token(subject=user.id)
    new_hashed_token = hash_token(new_raw_refresh)

    new_token_record = RefreshToken(
        user_id=user.id,
        token_hash=new_hashed_token,
        expires_at=new_refresh_expiry,
        is_revoked=False,
    )
    db.add(new_token_record)
    await db.commit()
    await db.refresh(user)

    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_raw_refresh,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserRead.model_validate(user),
    )


@router.get(
    "/me",
    response_model=UserRead,
    status_code=status.HTTP_200_OK,
    summary="Get Current User Profile",
    description="Fetches profile details of the authenticated user.",
)
async def get_current_user_profile(
    current_user: User = Depends(get_current_active_user),
) -> UserRead:
    return UserRead.model_validate(current_user)


@router.post(
    "/select_role",
    response_model=UserRead,
    status_code=status.HTTP_200_OK,
    summary="Select or Update User Role",
    description="Updates role between Customer and Creator for onboarding.",
)
async def select_role(
    payload: UpdateRoleRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> UserRead:
    current_user.role = payload.role
    await db.commit()
    await db.refresh(current_user)
    return UserRead.model_validate(current_user)
