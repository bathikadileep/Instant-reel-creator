from typing import Optional, Dict, Any
from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """API health status response."""
    status: str = Field(default="healthy", example="healthy")
    project_name: str
    environment: str
    version: str
    timestamp: str


class DBHealthResponse(BaseModel):
    """Database health status response."""
    status: str = Field(example="connected")
    database: str = Field(example="Neon PostgreSQL")
    responsive: bool
    error: Optional[str] = None
