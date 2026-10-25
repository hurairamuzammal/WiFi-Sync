"""
Pydantic data models for World of IT backend API requests and responses.
Matches plan/world_of_it_project_pack/docs/DATA_MODEL.md
"""

from datetime import datetime, timezone
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, EmailStr


class PlatformEnum(str, Enum):
    LINUX = "linux"
    WINDOWS = "windows"
    MACOS = "macos"
    ANDROID = "android"
    IOS = "ios"


class DeviceStatus(str, Enum):
    ONLINE = "online"
    OFFLINE = "offline"


class CommandAction(str, Enum):
    SHUTDOWN = "shutdown"
    RESTART = "restart"
    SLEEP = "sleep"
    HEALTH_CHECK = "health_check"


class CommandStatus(str, Enum):
    PENDING = "pending"
    SENT = "sent"
    ACCEPTED = "accepted"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    EXPIRED = "expired"
    CANCELLED = "cancelled"
    UNCONFIRMED = "unconfirmed"


# ---------------- Auth Models ----------------

class UserRegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)


class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    email: str


class UserResponse(BaseModel):
    id: str
    email: str
    created_at: str


# ---------------- Device Models ----------------

class DeviceCreate(BaseModel):
    display_name: str = Field(min_length=1, max_length=100)
    platform: PlatformEnum = PlatformEnum.LINUX
    agent_version: Optional[str] = "1.0.0"


class DeviceUpdate(BaseModel):
    display_name: Optional[str] = Field(None, min_length=1, max_length=100)
    clipboard_sync_enabled: Optional[bool] = None


class DeviceResponse(BaseModel):
    id: str
    user_id: str
    display_name: str
    platform: str
    agent_version: Optional[str]
    created_at: str
    last_seen_at: Optional[str]
    status: str
    revoked_at: Optional[str]
    clipboard_sync_enabled: bool


class DeviceRegistrationResponse(DeviceResponse):
    device_secret: str  # Only returned once upon creation


# ---------------- Pairing Models ----------------

class PairingCodeRequest(BaseModel):
    pass


class PairingCodeResponse(BaseModel):
    code: str
    expires_at: str


class PairingClaimRequest(BaseModel):
    code: str
    display_name: str
    platform: PlatformEnum = PlatformEnum.LINUX
    agent_version: Optional[str] = "1.0.0"


# ---------------- Command Models ----------------

class CommandCreate(BaseModel):
    device_id: str
    action: CommandAction
    ttl_seconds: int = Field(default=60, ge=10, le=600)


class CommandResponse(BaseModel):
    id: str
    user_id: str
    device_id: str
    action: str
    status: str
    created_at: str
    expires_at: str
    accepted_at: Optional[str] = None
    finished_at: Optional[str] = None
    error_code: Optional[str] = None
    result_summary: Optional[str] = None


class CommandUpdateAck(BaseModel):
    command_id: str
    status: CommandStatus = CommandStatus.ACCEPTED


class CommandResultPayload(BaseModel):
    command_id: str
    status: CommandStatus
    error_code: Optional[str] = None
    result_summary: Optional[str] = None


# ---------------- Clipboard Models ----------------

class ClipboardSyncEvent(BaseModel):
    event_id: str
    source_device_id: str
    text: str
    created_at: Optional[str] = None


# ---------------- Audit Models ----------------

class AuditEventResponse(BaseModel):
    id: str
    user_id: str
    device_id: Optional[str]
    command_id: Optional[str]
    event_type: str
    created_at: str
    metadata: Dict[str, Any]
