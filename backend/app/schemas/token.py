from typing import Optional
from pydantic import BaseModel


class Token(BaseModel):
    """JWT Token representation schema."""
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class TokenPayload(BaseModel):
    """Decoded JWT payload schema."""
    sub: Optional[str] = None
    exp: Optional[int] = None
    role: Optional[str] = None
