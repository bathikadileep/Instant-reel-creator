import json
import logging
import sys
import time
import uuid
from contextlib import asynccontextmanager
from typing import Callable

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from app import __version__
from app.api.v1.api import api_router
from app.core.config import settings
from app.core.database import check_db_connection
from app.core.exceptions import setup_exception_handlers

# ------------------------------------------------------------------------------
# Production Logging Configuration (JSON or Text format)
# ------------------------------------------------------------------------------
class JsonFormatter(logging.Formatter):
    """Outputs structured JSON log records for cloud log aggregators (Render, Datadog)."""
    def format(self, record: logging.LogRecord) -> str:
        log_obj = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "line": record.lineno,
        }
        if hasattr(record, "request_id"):
            log_obj["request_id"] = record.request_id
        if record.exc_info:
            log_obj["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_obj)


log_handler = logging.StreamHandler(sys.stdout)
if settings.LOG_FORMAT.lower() == "json":
    log_handler.setFormatter(JsonFormatter())
else:
    log_handler.setFormatter(
        logging.Formatter("%(asctime)s - [%(levelname)s] - %(name)s - %(message)s")
    )

root_logger = logging.getLogger()
root_logger.setLevel(getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO))
root_logger.handlers = [log_handler]

logger = logging.getLogger("instant_reel")

# ------------------------------------------------------------------------------
# Sentry Error Tracking & APM Initialization
# ------------------------------------------------------------------------------
if settings.SENTRY_DSN:
    try:
        import sentry_sdk
        from sentry_sdk.integrations.fastapi import FastApiIntegration
        from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

        sentry_sdk.init(
            dsn=settings.SENTRY_DSN,
            environment=settings.SENTRY_ENVIRONMENT or settings.ENVIRONMENT,
            traces_sample_rate=settings.SENTRY_TRACES_SAMPLE_RATE,
            profiles_sample_rate=settings.SENTRY_PROFILES_SAMPLE_RATE,
            send_default_pii=False,
            release=f"instant-reel@{__version__}",
            integrations=[
                FastApiIntegration(transaction_style="endpoint"),
                SqlalchemyIntegration(),
            ],
        )
        logger.info("[Sentry] Error tracking & APM initialized successfully.")
    except Exception as e:
        logger.warning(f"[Sentry] Failed to initialize Sentry: {e}")
else:
    logger.info("[Sentry] SENTRY_DSN not configured. Sentry tracking is disabled.")


# ------------------------------------------------------------------------------
# Lifespan Management
# ------------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown lifecycle manager."""
    logger.info(
        f"Starting {settings.PROJECT_NAME} v{__version__} "
        f"[{settings.ENVIRONMENT}] on port {settings.PORT}"
    )

    # Non-blocking connectivity ping during startup
    db_check = await check_db_connection()
    if db_check.get("responsive"):
        logger.info(f"Connected successfully to Neon PostgreSQL database ({db_check.get('database')}).")
    else:
        logger.warning(
            f"Database connectivity warning at startup: {db_check.get('error', 'Unreachable')}. "
            "Please verify your DATABASE_URL in .env if using Neon."
        )

    yield

    logger.info(f"Shutting down {settings.PROJECT_NAME}.")


# ------------------------------------------------------------------------------
# Custom Middlewares: Request ID, Performance Timing & Security Headers
# ------------------------------------------------------------------------------
class RequestTracingMiddleware(BaseHTTPMiddleware):
    """Assigns unique X-Request-ID and logs request latency."""
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        start_time = time.perf_counter()

        response: Response = await call_next(request)

        duration_ms = round((time.perf_counter() - start_time) * 1000, 2)
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Response-Time"] = f"{duration_ms}ms"

        if not request.url.path.startswith(("/metrics", "/api/v1/health")):
            logger.info(
                f"{request.method} {request.url.path} -> {response.status_code} "
                f"in {duration_ms}ms [req_id={request_id}]"
            )
        return response


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Enforces production HTTP security headers."""
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        response: Response = await call_next(request)
        if settings.SECURITY_HEADERS_ENABLED:
            response.headers["X-Content-Type-Options"] = "nosniff"
            response.headers["X-Frame-Options"] = "DENY"
            response.headers["X-XSS-Protection"] = "1; mode=block"
            response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
            if settings.ENVIRONMENT == "production":
                response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        return response


# ------------------------------------------------------------------------------
# Application Factory
# ------------------------------------------------------------------------------
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

    # 1. Custom Middlewares
    app.add_middleware(SecurityHeadersMiddleware)
    app.add_middleware(RequestTracingMiddleware)

    # 2. CORS Middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["X-Request-ID", "X-Response-Time"],
    )

    # 3. Register Exception Handlers
    setup_exception_handlers(app)

    # 4. Mount API Routers
    app.include_router(api_router, prefix=settings.API_V1_STR)
    from app.api.v1.endpoints import payments
    app.include_router(payments.router, prefix="/api/payments", tags=["Payments"])

    # 5. Prometheus Metrics Instrumentation (with FastAPI 0.141 compatibility patch)
    if settings.PROMETHEUS_METRICS_ENABLED:
        try:
            import prometheus_fastapi_instrumentator.routing as pfi_routing
            def _safe_get_route_name(scope, routes, route_name=None):
                for route in routes:
                    match, child_scope = route.matches(scope)
                    if match == pfi_routing.Match.FULL:
                        route_name = getattr(route, "path", getattr(route, "prefix", ""))
                        child_scope = {**scope, **child_scope}
                        if isinstance(route, pfi_routing.Mount) and route.routes:
                            child_route_name = _safe_get_route_name(child_scope, route.routes, route_name)
                            if child_route_name is None:
                                route_name = None
                            else:
                                route_name += child_route_name
                        return route_name
                    elif match == pfi_routing.Match.PARTIAL and route_name is None:
                        route_name = getattr(route, "path", getattr(route, "prefix", ""))
                return None
            pfi_routing._get_route_name = _safe_get_route_name

            from prometheus_fastapi_instrumentator import Instrumentator
            Instrumentator(
                should_group_status_codes=False,
                should_ignore_untemplated=True,
                should_respect_env_var=False,
                excluded_handlers=["/metrics", "/api/v1/health", "/docs", "/openapi.json"],
            ).instrument(app).expose(app, endpoint="/metrics", tags=["Monitoring"])
            logger.info("[Prometheus] Metrics instrumented at /metrics")
        except Exception as e:
            logger.warning(f"[Prometheus] Metrics instrumentation failed: {e}")

    # 6. Convenience Root Endpoint
    @app.get("/", tags=["Root"])
    async def root():
        return {
            "name": settings.PROJECT_NAME,
            "version": __version__,
            "environment": settings.ENVIRONMENT,
            "docs": "/docs" if settings.DEBUG else "Disabled in production",
            "health": f"{settings.API_V1_STR}/health",
            "metrics": "/metrics" if settings.PROMETHEUS_METRICS_ENABLED else "Disabled",
            "neon_status": "configured",
        }

    return app


app = create_application()
