from typing import List, Union
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(".env", "backend/.env"),
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

    PROJECT_NAME: str = "Instant Reel API"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    API_V1_STR: str = "/api/v1"

    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # Neon PostgreSQL Database Settings
    # Neon provides serverless Postgres connection strings, usually postgresql://...
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/instant_reel"
    SYNC_DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/instant_reel"

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def assemble_async_db_connection(cls, v: str) -> str:
        if not v:
            return v
        # Ensure asyncpg driver prefix for SQLAlchemy async engine
        if v.startswith("postgres://"):
            v = v.replace("postgres://", "postgresql+asyncpg://", 1)
        elif v.startswith("postgresql://") and not v.startswith("postgresql+asyncpg://"):
            v = v.replace("postgresql://", "postgresql+asyncpg://", 1)
        
        # Asyncpg uses ?ssl=require rather than ?sslmode=require
        if "sslmode=require" in v:
            v = v.replace("sslmode=require", "ssl=require")
            
        # Asyncpg does not support channel_binding query param
        if "channel_binding=require" in v:
            v = v.replace("&channel_binding=require", "").replace("channel_binding=require&", "").replace("?channel_binding=require", "?")
            if v.endswith("?"):
                v = v[:-1]
        return v

    @field_validator("SYNC_DATABASE_URL", mode="before")
    @classmethod
    def assemble_sync_db_connection(cls, v: str) -> str:
        if not v:
            return v
        # Ensure standard driver prefix for Alembic / sync operations
        if v.startswith("postgres://"):
            v = v.replace("postgres://", "postgresql://", 1)
        elif v.startswith("postgresql+asyncpg://"):
            v = v.replace("postgresql+asyncpg://", "postgresql://", 1)
        return v

    # Connection pool options
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20
    DB_POOL_TIMEOUT: int = 30
    DB_POOL_RECYCLE: int = 1800

    # JWT Authentication & Security
    JWT_SECRET_KEY: str = "instant_reel_super_secure_default_secret_key_change_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day

    # CORS Settings
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "*",
    ]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",") if i.strip()]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)


settings = Settings()
