"""
Configuration settings for World of IT backend.
Loaded from environment variables with safe defaults.
"""

import os
from pydantic import BaseModel


class Settings(BaseModel):
    SECRET_KEY: str = os.getenv("SECRET_KEY", "world-of-it-production-super-secret-key-change-in-prod-2026")
    DATABASE_PATH: str = os.getenv("DATABASE_PATH", "world_of_it.db")
    TOKEN_EXPIRE_MINUTES: int = int(os.getenv("TOKEN_EXPIRE_MINUTES", "1440"))  # 24 hours
    HEARTBEAT_TIMEOUT_SECONDS: int = int(os.getenv("HEARTBEAT_TIMEOUT_SECONDS", "45"))
    PAIRING_CODE_TTL_MINUTES: int = int(os.getenv("PAIRING_CODE_TTL_MINUTES", "5"))
    COMMAND_DEFAULT_TTL_SECONDS: int = int(os.getenv("COMMAND_DEFAULT_TTL_SECONDS", "60"))
    ALLOWED_HOSTS: list[str] = ["*"]


settings = Settings()
