import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import __version__
from app.api.v1.api import api_router
from app.core.config import settings
from app.core.database import check_db_connection
from app.core.exceptions import setup_exception_handlers

# Configure structured logging
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format="%(asctime)s - [%(levelname)s] - %(name)s - %(message)s",
)
logger = logging.getLogger("instant_reel")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown lifecycle manager."""
    logger.info(f"Starting {settings.PROJECT_NAME} v{__version__} [{settings.ENVIRONMENT}]")
    
    # Non-blocking connectivity ping during startup
    db_check = await check_db_connection()
    if db_check.get("responsive"):
        logger.info("Connected successfully to Neon PostgreSQL database.")
    else:
        logger.warning(
            f"Database connectivity warning at startup: {db_check.get('error', 'Unreachable')}. "
            "Please verify your DATABASE_URL in .env if using Neon."
        )
    
    yield
    
    logger.info(f"Shutting down {settings.PROJECT_NAME}.")


def create_application() -> FastAPI:
    """FastAPI Application Factory."""
    app = FastAPI(
        title=settings.PROJECT_NAME,
        description="On-demand Instant Reel Creator platform serving Maripeda, Mahabubabad, Khammam, and Warangal.",
        version=__version__,
        docs_url="/docs" if settings.DEBUG else None,
        redoc_url="/redoc" if settings.DEBUG else None,
        openapi_url=f"{settings.API_V1_STR}/openapi.json",
        lifespan=lifespan,
    )

    # Configure CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Register Exception Handlers
    setup_exception_handlers(app)

    # Mount API Routers
    app.include_router(api_router, prefix=settings.API_V1_STR)

    # Convenience root endpoint
    @app.get("/", tags=["Root"])
    async def root():
        return {
            "name": settings.PROJECT_NAME,
            "version": __version__,
            "environment": settings.ENVIRONMENT,
            "docs": "/docs" if settings.DEBUG else "Disabled in production",
            "health": f"{settings.API_V1_STR}/health",
        }

    return app


app = create_application()
