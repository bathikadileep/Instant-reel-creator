import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field

from app.models.schema_models import PaymentMethod, PaymentStatus


class CreateOrderRequest(BaseModel):
    booking_id: uuid.UUID
    payment_method: PaymentMethod = PaymentMethod.RAZORPAY_FULL


class CreateOrderResponse(BaseModel):
    payment_id: uuid.UUID
    booking_id: uuid.UUID
    booking_code: str
    razorpay_order_id: str
    razorpay_key_id: str
    amount: float = Field(..., description="Amount to be paid online in INR")
    amount_in_paise: int = Field(..., description="Smallest currency unit for Razorpay Checkout")
    currency: str = "INR"
    payment_method: PaymentMethod
    total_booking_amount: float
    advance_amount: float
    remaining_cash_amount: float


class VerifyPaymentRequest(BaseModel):
    payment_id: uuid.UUID
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str


class PaymentVerificationResponse(BaseModel):
    success: bool
    message: str
    payment_id: uuid.UUID
    booking_id: uuid.UUID
    booking_code: str
    payment_status: PaymentStatus
    booking_status: str
    total_amount: float
    advance_amount: float
    remaining_amount: float


class CollectCashRequest(BaseModel):
    booking_id: uuid.UUID


class CashCollectionResponse(BaseModel):
    success: bool
    message: str
    booking_id: uuid.UUID
    booking_code: str
    cash_collected: bool
    cash_collected_at: datetime
    remaining_amount: float
    payment_status: PaymentStatus


class PaymentConfigRead(BaseModel):
    id: uuid.UUID
    cod_enabled: bool
    cod_minimum_advance: float
    updated_at: datetime


class PaymentConfigUpdate(BaseModel):
    cod_enabled: Optional[bool] = None
    cod_minimum_advance: Optional[float] = Field(None, gt=0, description="Minimum advance in INR (must be > 0)")


class RefundRequest(BaseModel):
    reason: Optional[str] = Field(None, description="Reason for issuing refund")


class RefundResponse(BaseModel):
    success: bool
    message: str
    payment_id: uuid.UUID
    refund_id: Optional[str] = None
    amount_refunded: float
    status: PaymentStatus


class PaymentListItem(BaseModel):
    id: uuid.UUID
    booking_id: uuid.UUID
    booking_code: str
    customer_id: uuid.UUID
    customer_name: Optional[str] = None
    customer_mobile: str
    creator_name: Optional[str] = None
    city: str
    package_name: str
    amount: float
    currency: str
    payment_method: Optional[str] = None
    payment_status: PaymentStatus
    razorpay_order_id: Optional[str] = None
    razorpay_payment_id: Optional[str] = None
    total_amount: float
    advance_amount: float
    remaining_amount: float
    cash_collected: bool
    cash_collected_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime


class AdminPaymentSummary(BaseModel):
    total_revenue: float
    online_revenue: float
    cod_advance_revenue: float
    cash_collected: float
    cod_outstanding: float
    successful_payments: int
    failed_payments: int
    refunded_payments: int


class PaginatedPaymentsResponse(BaseModel):
    items: List[PaymentListItem]
    total: int
    page: int
    page_size: int
    total_pages: int
