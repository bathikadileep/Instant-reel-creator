from datetime import datetime, timezone
from fastapi import APIRouter, status
from fastapi.responses import JSONResponse

from app import __version__
from app.core.config import settings
from app.core.database import check_db_connection
from app.schemas.health import HealthResponse, DBHealthResponse

router = APIRouter()


@router.get(
    "/health",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="API Health Status",
    description="Returns the current operational status of the Instant Reel API.",
)
async def get_health() -> HealthResponse:
    return HealthResponse(
        status="healthy",
        project_name=settings.PROJECT_NAME,
        environment=settings.ENVIRONMENT,
        version=__version__,
        timestamp=datetime.now(timezone.utc).isoformat(),
    )


@router.get(
    "/health/db",
    response_model=DBHealthResponse,
    summary="Database Connection Health",
    description="Executes a live ping against Neon PostgreSQL to verify serverless connection status.",
)
async def get_db_health():
    result = await check_db_connection()
    if not result.get("responsive", False):
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content=result,
        )
    return result
