"""
FastAPI application for World of IT backend.
Handles REST endpoints, token auth, WebSocket agent connections, command dispatch, and clipboard routing.
"""

import asyncio
import json
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Dict, List, Optional, Any

from fastapi import (
    FastAPI,
    HTTPException,
    Depends,
    Request,
    WebSocket,
    WebSocketDisconnect,
    Query,
    status,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from backend.config import settings
from backend.database import (
    init_db,
    create_user,
    get_user_by_email,
    get_user_by_id,
    create_device,
    get_device_by_id,
    list_devices_by_user,
    update_device,
    revoke_device,
    update_device_presence,
    verify_device_credentials,
    create_pairing_record,
    claim_pairing_record,
    create_command,
    get_command_by_id,
    list_commands_by_user,
    update_command_status,
    cancel_command,
    record_audit_event,
    list_audit_events_by_user,
    expire_stale_records,
    get_utc_now,
)
from backend.models import (
    UserRegisterRequest,
    UserLoginRequest,
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    TokenResponse,
    UserResponse,
    DeviceCreate,
    DeviceUpdate,
    DeviceResponse,
    DeviceRegistrationResponse,
    PairingCodeResponse,
    PairingClaimRequest,
    CommandCreate,
    CommandResponse,
    AuditEventResponse,
    ClipboardSyncEvent,
    CommandStatus,
)
from backend.security import (
    hash_password,
    verify_password,
    generate_device_secret,
    hash_device_secret,
    create_access_token,
    verify_access_token,
    generate_pairing_code,
    rate_limiter,
)


# ---------------- WebSocket Connection Manager ----------------

class ConnectionManager:
    """Manages active device WebSocket connections."""

    def __init__(self):
        # Maps device_id -> WebSocket
        self.active_agents: Dict[str, WebSocket] = {}
        # Maps user_id -> set of device_ids
        self.user_devices: Dict[str, set[str]] = {}

    async def connect(self, device_id: str, user_id: str, websocket: WebSocket):
        await websocket.accept()
        self.active_agents[device_id] = websocket
        if user_id not in self.user_devices:
            self.user_devices[user_id] = set()
        self.user_devices[user_id].add(device_id)
        update_device_presence(device_id, "online")

    def disconnect(self, device_id: str, user_id: str):
        self.active_agents.pop(device_id, None)
        if user_id in self.user_devices:
            self.user_devices[user_id].discard(device_id)
        update_device_presence(device_id, "offline")

    def is_online(self, device_id: str) -> bool:
        return device_id in self.active_agents

    async def send_command(self, device_id: str, command_payload: dict) -> bool:
        ws = self.active_agents.get(device_id)
        if not ws:
            return False
        try:
            await ws.send_json({
                "type": "command_dispatch",
                "command": command_payload
            })
            return True
        except Exception:
            return False

    async def broadcast_clipboard(self, user_id: str, source_device_id: str, payload: dict):
        """Dispatches clipboard text to other authorized online devices for the user."""
        target_device_ids = self.user_devices.get(user_id, set())
        for dev_id in list(target_device_ids):
            if dev_id != source_device_id and dev_id in self.active_agents:
                dev = get_device_by_id(dev_id)
                if dev and dev.get("clipboard_sync_enabled"):
                    try:
                        await self.active_agents[dev_id].send_json({
                            "type": "clipboard_update",
                            "data": payload
                        })
                    except Exception:
                        pass


manager = ConnectionManager()


# ---------------- Lifespan & Periodic Cleanup ----------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: ensure tables exist
    init_db()
    
    # Background task for expiring stale commands
    async def cleanup_loop():
        while True:
            try:
                expire_stale_records()
            except Exception:
                pass
            await asyncio.sleep(30)

    task = asyncio.create_task(cleanup_loop())
    yield
    task.cancel()


app = FastAPI(
    title="World of IT API",
    version="1.0.0",
    description="Cross-platform device connectivity, remote actions, and clipboard synchronization API.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security_scheme = HTTPBearer(auto_error=False)


# ---------------- Auth Dependencies ----------------

async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
) -> Dict[str, Any]:
    if not credentials or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    payload = verify_access_token(credentials.credentials)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user = get_user_by_id(payload["sub"])
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user


# ---------------- Health & Diagnostics ----------------

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "world-of-it-backend",
        "time": get_utc_now(),
        "active_connections": len(manager.active_agents),
    }


# ---------------- Auth Endpoints ----------------

@app.post("/api/v1/auth/signup", response_model=TokenResponse)
def signup(req: UserRegisterRequest):
    existing = get_user_by_email(req.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email already exists",
        )
    pwd_hash = hash_password(req.password)
    user = create_user(req.email, pwd_hash)
    token = create_access_token(user["id"], user["email"])
    record_audit_event(user["id"], "user_signup", metadata={"email": user["email"]})
    return {
        "access_token": token,
        "token_type": "bearer",
        "user_id": user["id"],
        "email": user["email"],
    }


@app.post("/api/v1/auth/login", response_model=TokenResponse)
def login(req: UserLoginRequest):
    user = get_user_by_email(req.email)
    if not user or not verify_password(req.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    token = create_access_token(user["id"], user["email"])
    record_audit_event(user["id"], "user_login", metadata={"email": user["email"]})
    return {
        "access_token": token,
        "token_type": "bearer",
        "user_id": user["id"],
        "email": user["email"],
    }


@app.post("/api/v1/auth/forgot-password", response_model=ForgotPasswordResponse)
def forgot_password(req: ForgotPasswordRequest, request: Request):
    client_ip = request.client.host if request.client else "unknown"
    allowed, err_msg = rate_limiter.check_and_record(
        ip=client_ip,
        email=req.email,
        max_per_ip=5,
        max_per_email=3,
        window_seconds=900,
        cooldown_seconds=60,
    )
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=err_msg or "Rate limit exceeded. Please try again later.",
        )

    user = get_user_by_email(req.email)
    if user:
        record_audit_event(user["id"], "password_reset_requested", metadata={"email": user["email"], "ip": client_ip})

    return {
        "status": "ok",
        "message": f"If an account exists for {req.email}, password recovery instructions have been dispatched.",
    }


@app.get("/api/v1/auth/me", response_model=UserResponse)
def get_me(current_user: Dict[str, Any] = Depends(get_current_user)):
    return {
        "id": current_user["id"],
        "email": current_user["email"],
        "created_at": current_user["created_at"],
    }


# ---------------- Device Endpoints ----------------

@app.post("/api/v1/devices", response_model=DeviceRegistrationResponse)
def register_device(
    req: DeviceCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """Direct device registration returning a one-time revocable credential."""
    secret = generate_device_secret()
    secret_hash = hash_device_secret(secret)
    device = create_device(
        user_id=current_user["id"],
        display_name=req.display_name,
        platform=req.platform.value,
        device_secret_hash=secret_hash,
        agent_version=req.agent_version,
    )
    record_audit_event(
        current_user["id"],
        "device_registered",
        device_id=device["id"],
        metadata={"display_name": req.display_name, "platform": req.platform.value},
    )
    device["device_secret"] = secret
    return device


@app.get("/api/v1/devices", response_model=List[DeviceResponse])
def get_devices(
    include_revoked: bool = False,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    devices = list_devices_by_user(current_user["id"], include_revoked=include_revoked)
    # Dynamically annotate status with actual live connection presence
    for d in devices:
        if d.get("revoked_at"):
            d["status"] = "offline"
        elif manager.is_online(d["id"]):
            d["status"] = "online"
    return devices


@app.get("/api/v1/devices/{device_id}", response_model=DeviceResponse)
def get_device(
    device_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    device = get_device_by_id(device_id)
    if not device or device["user_id"] != current_user["id"]:
        raise HTTPException(status_code=404, detail="Device not found")
    if device.get("revoked_at"):
        device["status"] = "offline"
    elif manager.is_online(device["id"]):
        device["status"] = "online"
    return device


@app.patch("/api/v1/devices/{device_id}", response_model=DeviceResponse)
def update_device_details(
    device_id: str,
    req: DeviceUpdate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    device = update_device(
        device_id=device_id,
        user_id=current_user["id"],
        display_name=req.display_name,
        clipboard_sync_enabled=req.clipboard_sync_enabled,
    )
    if not device:
        raise HTTPException(status_code=404, detail="Device not found or revoked")
    record_audit_event(
        current_user["id"],
        "device_updated",
        device_id=device_id,
        metadata={"display_name": req.display_name, "clipboard_sync": req.clipboard_sync_enabled},
    )
    if manager.is_online(device_id):
        device["status"] = "online"
    return device


@app.delete("/api/v1/devices/{device_id}")
def revoke_device_access(
    device_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    success = revoke_device(device_id, current_user["id"])
    if not success:
        raise HTTPException(status_code=404, detail="Device not found or already revoked")
    
    # Close any active connection immediately
    if manager.is_online(device_id):
        ws = manager.active_agents.get(device_id)
        if ws:
            asyncio.create_task(ws.close(code=1008, reason="Device credentials revoked"))
        manager.disconnect(device_id, current_user["id"])

    record_audit_event(
        current_user["id"],
        "device_revoked",
        device_id=device_id,
        metadata={"revoked_by": current_user["id"]},
    )
    return {"status": "success", "message": "Device credentials permanently revoked"}


# ---------------- Pairing Endpoints (US-08) ----------------

@app.post("/api/v1/devices/pair/request", response_model=PairingCodeResponse)
def request_pairing_code(
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """Generates an expiring 6-character code to pair a new device."""
    code = generate_pairing_code()
    expires_dt = datetime.fromtimestamp(
        datetime.now(timezone.utc).timestamp() + (settings.PAIRING_CODE_TTL_MINUTES * 60),
        tz=timezone.utc,
    )
    expires_at = expires_dt.isoformat()
    create_pairing_record(current_user["id"], code, expires_at)
    record_audit_event(current_user["id"], "pairing_code_generated", metadata={"expires_at": expires_at})
    return {"code": code, "expires_at": expires_at}


@app.post("/api/v1/devices/pair/claim", response_model=DeviceRegistrationResponse)
def claim_pairing_code(req: PairingClaimRequest):
    """Allows a new agent with a pairing code to register itself securely."""
    secret = generate_device_secret()
    secret_hash = hash_device_secret(secret)
    device = claim_pairing_record(
        code=req.code,
        display_name=req.display_name,
        platform=req.platform.value,
        device_secret_hash=secret_hash,
        agent_version=req.agent_version,
    )
    if not device:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid, expired, or already-claimed pairing code",
        )
    record_audit_event(
        device["user_id"],
        "device_paired_via_code",
        device_id=device["id"],
        metadata={"display_name": req.display_name, "platform": req.platform.value},
    )
    device["device_secret"] = secret
    return device


# ---------------- Command Endpoints (US-16, 17, 18, 19, 20, 24) ----------------

@app.post("/api/v1/commands", response_model=CommandResponse)
async def dispatch_command(
    req: CommandCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """Enforces strict action allowlist and routes command to online device."""
    device = get_device_by_id(req.device_id)
    if not device or device["user_id"] != current_user["id"]:
        raise HTTPException(status_code=404, detail="Target device not found")
    if device.get("revoked_at"):
        raise HTTPException(status_code=400, detail="Cannot send commands to a revoked device")

    cmd = create_command(
        user_id=current_user["id"],
        device_id=req.device_id,
        action=req.action.value,
        ttl_seconds=req.ttl_seconds,
    )
    if not cmd:
        raise HTTPException(status_code=400, detail="Failed to initialize command")

    record_audit_event(
        current_user["id"],
        "command_created",
        device_id=req.device_id,
        command_id=cmd["id"],
        metadata={"action": req.action.value, "ttl": req.ttl_seconds},
    )

    # If target device is currently connected over WebSocket, dispatch immediately
    if manager.is_online(req.device_id):
        delivered = await manager.send_command(req.device_id, cmd)
        if delivered:
            cmd["status"] = "sent"
            update_command_status(cmd["id"], "sent")
    else:
        # Honest representation: Target is offline
        cmd["status"] = "unconfirmed"
        update_command_status(
            cmd["id"],
            "unconfirmed",
            result_summary="Target device is offline; command queued until expiry",
        )

    return cmd


@app.get("/api/v1/commands", response_model=List[CommandResponse])
def get_commands(
    limit: int = 50,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    return list_commands_by_user(current_user["id"], limit=limit)


@app.get("/api/v1/commands/{command_id}", response_model=CommandResponse)
def get_command(
    command_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    cmd = get_command_by_id(command_id)
    if not cmd or cmd["user_id"] != current_user["id"]:
        raise HTTPException(status_code=404, detail="Command not found")
    return cmd


@app.post("/api/v1/commands/{command_id}/cancel")
def cancel_pending_command(
    command_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    success = cancel_command(command_id, current_user["id"])
    if not success:
        raise HTTPException(
            status_code=400,
            detail="Command could not be cancelled (already executed, expired, or not pending)",
        )
    record_audit_event(
        current_user["id"],
        "command_cancelled",
        command_id=command_id,
    )
    return {"status": "success", "message": "Command successfully cancelled"}


# ---------------- Clipboard Endpoints (US-12, 13, 14, 15) ----------------

@app.post("/api/v1/clipboard")
async def send_clipboard_text(
    event: ClipboardSyncEvent,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """Dispatches text clipboard update without persistent plaintext storage."""
    source_device = get_device_by_id(event.source_device_id)
    if not source_device or source_device["user_id"] != current_user["id"]:
        raise HTTPException(status_code=404, detail="Source device not found")
    if not source_device.get("clipboard_sync_enabled"):
        raise HTTPException(status_code=400, detail="Clipboard sync is disabled on source device")

    # Broadcast to all other authorized online devices
    await manager.broadcast_clipboard(
        user_id=current_user["id"],
        source_device_id=event.source_device_id,
        payload={
            "event_id": event.event_id,
            "source_device_id": event.source_device_id,
            "text": event.text,
            "timestamp": get_utc_now(),
        },
    )
    return {"status": "success", "message": "Clipboard event dispatched to authorized devices"}


# ---------------- Audit Endpoints (US-23) ----------------

@app.get("/api/v1/audit", response_model=List[AuditEventResponse])
def get_audit_trail(
    limit: int = 100,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    return list_audit_events_by_user(current_user["id"], limit=limit)


# ---------------- WebSocket Agent Connection ----------------

@app.websocket("/ws/agent/{device_id}")
async def agent_websocket_endpoint(
    websocket: WebSocket,
    device_id: str,
    secret: Optional[str] = Query(None),
):
    """
    Authenticated persistent WebSocket endpoint for device agents.
    Handles heartbeats, command delivery, ack, result reporting, and clipboard sync.
    """
    # Verify device credentials
    if not secret:
        await websocket.close(code=1008, reason="Missing device secret parameter")
        return

    device = verify_device_credentials(device_id, secret)
    if not device:
        await websocket.close(code=1008, reason="Invalid or revoked device credentials")
        return

    user_id = device["user_id"]
    await manager.connect(device_id, user_id, websocket)
    record_audit_event(user_id, "agent_connected", device_id=device_id)

    try:
        while True:
            data = await websocket.receive_text()
            try:
                msg = json.loads(data)
            except Exception:
                continue

            msg_type = msg.get("type")

            if msg_type == "heartbeat":
                update_device_presence(device_id, "online")
                await websocket.send_json({"type": "heartbeat_ack", "timestamp": get_utc_now()})

            elif msg_type == "command_ack":
                cmd_id = msg.get("command_id")
                if cmd_id:
                    update_command_status(cmd_id, "accepted", accepted_at=get_utc_now())

            elif msg_type == "command_result":
                cmd_id = msg.get("command_id")
                outcome = msg.get("status", "unconfirmed")
                err_code = msg.get("error_code")
                summary = msg.get("result_summary")
                if cmd_id:
                    update_command_status(
                        command_id=cmd_id,
                        status=outcome,
                        finished_at=get_utc_now(),
                        error_code=err_code,
                        result_summary=summary,
                    )
                    record_audit_event(
                        user_id,
                        "command_completed",
                        device_id=device_id,
                        command_id=cmd_id,
                        metadata={"status": outcome, "summary": summary},
                    )

            elif msg_type == "clipboard_sync":
                # Ensure device has clipboard sync enabled
                curr_dev = get_device_by_id(device_id)
                if curr_dev and curr_dev.get("clipboard_sync_enabled"):
                    text = msg.get("text", "")
                    evt_id = msg.get("event_id") or get_utc_now()
                    await manager.broadcast_clipboard(
                        user_id=user_id,
                        source_device_id=device_id,
                        payload={
                            "event_id": evt_id,
                            "source_device_id": device_id,
                            "text": text,
                            "timestamp": get_utc_now(),
                        },
                    )

    except WebSocketDisconnect:
        manager.disconnect(device_id, user_id)
        record_audit_event(user_id, "agent_disconnected", device_id=device_id)
    except Exception:
        manager.disconnect(device_id, user_id)
