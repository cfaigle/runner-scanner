from pydantic_settings import BaseSettings
from functools import lru_cache
import secrets
import os


class Settings(BaseSettings):
    # App settings
    APP_NAME: str = "Runner Race Timer"
    DEBUG: bool = True
    
    # Database - use absolute path
    DATABASE_URL: str = "sqlite:///./race_timer.db"
    
    # Security
    SECRET_KEY: str = secrets.token_urlsafe(32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 1 week
    
    # Encryption for packets
    ENCRYPTION_KEY: str = secrets.token_urlsafe(32)
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Sync
    SYNC_INTERVAL_SECONDS: int = 5
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()
