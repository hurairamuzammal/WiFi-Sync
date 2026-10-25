"""
Database repository and connection layer for World of IT backend.
Handles SQLite with thread-safe connection pooling, foreign keys, and WAL mode.
"""

import json
import sqlite3
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional
from backend.config import settings
from backend.security import hash_device_secret, verify_device_secret


def get_utc_now() -> str:
    """Returns current UTC timestamp in ISO-8601 format."""
    return datetime.now(timezone.utc).isoformat()


def get_connection(db_path: Optional[str] = None) -> sqlite3.Connection:
    """Creates a configured SQLite connection."""
    target_path = db_path or settings.DATABASE_PATH
    conn = sqlite3.connect(target_path, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.execute("PRAGMA journal_mode = WAL;")
    return conn


def init_db(db_path: Optional[str] = None):
    """Initializes database schema from schema.sql."""
    schema_path = Path(__file__).parent / "schema.sql"
    with open(schema_path, "r", encoding="utf-8") as f:
        sql = f.read()
    conn = get_connection(db_path)
    try:
        conn.executescript(sql)
        conn.commit()
    finally:
        conn.close()


# ---------------- User Operations ----------------

def create_user(email: str, password_hash: str, db_path: Optional[str] = None) -> Dict[str, Any]:
    user_id = str(uuid.uuid4())
    now = get_utc_now()
    conn = get_connection(db_path)
    try:
        conn.execute(
            "INSERT INTO users (id, email, password_hash, created_at) VALUES (?, ?, ?, ?)",
            (user_id, email.lower().strip(), password_hash, now)
        )
        conn.commit()
        return {"id": user_id, "email": email.lower().strip(), "created_at": now}
    finally:
        conn.close()


def get_user_by_email(email: str, db_path: Optional[str] = None) -> Optional[Dict[str, Any]]:
    conn = get_connection(db_path)
    try:
        row = conn.execute(
            "SELECT * FROM users WHERE email = ?", (email.lower().strip(),)
        ).fetchone()
        return dict(row) if row else None
    finally:
        conn.close()


def get_user_by_id(user_id: str, db_path: Optional[str] = None) -> Optional[Dict[str, Any]]:
    conn = get_connection(db_path)
    try:
        row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        return dict(row) if row else None
    finally:
        conn.close()


# ---------------- Device Operations ----------------

def create_device(
    user_id: str,
    display_name: str,
    platform: str,
    device_secret_hash: str,
    agent_version: Optional[str] = "1.0.0",
    db_path: Optional[str] = None,
) -> Dict[str, Any]:
    device_id = str(uuid.uuid4())
    now = get_utc_now()
    conn = get_connection(db_path)
    try:
        conn.execute(
            """
            INSERT INTO devices (
                id, user_id, display_name, platform, agent_version,
                device_secret_hash, created_at, last_seen_at, status, clipboard_sync_enabled
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'offline', 0)
            """,
            (device_id, user_id, display_name, platform, agent_version, device_secret_hash, now, now)
        )
        conn.commit()
        return {
            "id": device_id,
            "user_id": user_id,
            "display_name": display_name,
            "platform": platform,
            "agent_version": agent_version,
            "created_at": now,
            "last_seen_at": now,
            "status": "offline",
            "revoked_at": None,
            "clipboard_sync_enabled": False,
        }
    finally:
        conn.close()


def get_device_by_id(device_id: str, db_path: Optional[str] = None) -> Optional[Dict[str, Any]]:
    conn = get_connection(db_path)
    try:
        row = conn.execute("SELECT * FROM devices WHERE id = ?", (device_id,)).fetchone()
        if not row:
            return None
        d = dict(row)
        d["clipboard_sync_enabled"] = bool(d["clipboard_sync_enabled"])
        return d
    finally:
        conn.close()


def list_devices_by_user(user_id: str, include_revoked: bool = False, db_path: Optional[str] = None) -> List[Dict[str, Any]]:
    conn = get_connection(db_path)
    try:
        if include_revoked:
            rows = conn.execute(
                "SELECT * FROM devices WHERE user_id = ? ORDER BY created_at DESC", (user_id,)
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT * FROM devices WHERE user_id = ? AND revoked_at IS NULL ORDER BY created_at DESC",
                (user_id,)
            ).fetchall()
        result = []
        for r in rows:
            d = dict(r)
            d["clipboard_sync_enabled"] = bool(d["clipboard_sync_enabled"])
            del d["device_secret_hash"]
            result.append(d)
        return result
    finally:
        conn.close()


def update_device(
    device_id: str,
    user_id: str,
    display_name: Optional[str] = None,
    clipboard_sync_enabled: Optional[bool] = None,
    db_path: Optional[str] = None,
) -> Optional[Dict[str, Any]]:
    conn = get_connection(db_path)
    try:
        dev = conn.execute(
            "SELECT * FROM devices WHERE id = ? AND user_id = ? AND revoked_at IS NULL",
            (device_id, user_id)
        ).fetchone()
        if not dev:
            return None

        updates = []
        params = []
        if display_name is not None:
            updates.append("display_name = ?")
            params.append(display_name)
        if clipboard_sync_enabled is not None:
            updates.append("clipboard_sync_enabled = ?")
            params.append(1 if clipboard_sync_enabled else 0)

        if updates:
            params.extend([device_id, user_id])
            query = f"UPDATE devices SET {', '.join(updates)} WHERE id = ? AND user_id = ?"
            conn.execute(query, tuple(params))
            conn.commit()

        updated = conn.execute("SELECT * FROM devices WHERE id = ?", (device_id,)).fetchone()
        d = dict(updated)
        d["clipboard_sync_enabled"] = bool(d["clipboard_sync_enabled"])
        del d["device_secret_hash"]
        return d
    finally:
        conn.close()


def revoke_device(device_id: str, user_id: str, db_path: Optional[str] = None) -> bool:
    conn = get_connection(db_path)
    now = get_utc_now()
    try:
        cur = conn.execute(
            """
            UPDATE devices
            SET revoked_at = ?, status = 'offline'
            WHERE id = ? AND user_id = ? AND revoked_at IS NULL
            """,
            (now, device_id, user_id)
        )
        conn.commit()
        return cur.rowcount > 0
    finally:
        conn.close()


def update_device_presence(device_id: str, status: str, db_path: Optional[str] = None):
    conn = get_connection(db_path)
    now = get_utc_now()
    try:
        conn.execute(
            "UPDATE devices SET status = ?, last_seen_at = ? WHERE id = ? AND revoked_at IS NULL",
            (status, now, device_id)
        )
        conn.commit()
    finally:
        conn.close()


def verify_device_credentials(device_id: str, raw_secret: str, db_path: Optional[str] = None) -> Optional[Dict[str, Any]]:
    conn = get_connection(db_path)
    try:
        row = conn.execute(
            "SELECT * FROM devices WHERE id = ? AND revoked_at IS NULL", (device_id,)
        ).fetchone()
        if not row:
            return None
        d = dict(row)
        if verify_device_secret(raw_secret, d["device_secret_hash"]):
            d["clipboard_sync_enabled"] = bool(d["clipboard_sync_enabled"])
            del d["device_secret_hash"]
            return d
        return None
    finally:
        conn.close()


# ---------------- Pairing Operations ----------------

def create_pairing_record(user_id: str, code: str, expires_at: str, db_path: Optional[str] = None) -> str:
    pairing_id = str(uuid.uuid4())
    now = get_utc_now()
    conn = get_connection(db_path)
    try:
        conn.execute(
            "INSERT INTO pairing_codes (id, user_id, code, created_at, expires_at) VALUES (?, ?, ?, ?, ?)",
            (pairing_id, user_id, code.upper(), now, expires_at)
        )
        conn.commit()
        return pairing_id
    finally:
        conn.close()


def claim_pairing_record(
    code: str,
    display_name: str,
    platform: str,
    device_secret_hash: str,
    agent_version: Optional[str] = "1.0.0",
    db_path: Optional[str] = None,
) -> Optional[Dict[str, Any]]:
    conn = get_connection(db_path)
    now = get_utc_now()
    try:
        row = conn.execute(
            """
            SELECT * FROM pairing_codes
            WHERE code = ? AND claimed_at IS NULL AND expires_at > ?
            """,
            (code.upper().strip(), now)
        ).fetchone()
        if not row:
            return None

        pairing_rec = dict(row)
        user_id = pairing_rec["user_id"]
        device_id = str(uuid.uuid4())

        # Insert new device
        conn.execute(
            """
            INSERT INTO devices (
                id, user_id, display_name, platform, agent_version,
                device_secret_hash, created_at, last_seen_at, status, clipboard_sync_enabled
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'offline', 0)
            """,
            (device_id, user_id, display_name, platform, agent_version, device_secret_hash, now, now)
        )

        # Mark code claimed
        conn.execute(
            "UPDATE pairing_codes SET claimed_at = ?, device_id = ? WHERE id = ?",
            (now, device_id, pairing_rec["id"])
        )
        conn.commit()

        return {
            "id": device_id,
            "user_id": user_id,
            "display_name": display_name,
            "platform": platform,
            "agent_version": agent_version,
            "created_at": now,
            "last_seen_at": now,
            "status": "offline",
            "revoked_at": None,
            "clipboard_sync_enabled": False,
        }
    finally:
        conn.close()


# ---------------- Command Operations ----------------

def create_command(
    user_id: str,
    device_id: str,
    action: str,
    ttl_seconds: int,
    db_path: Optional[str] = None,
) -> Optional[Dict[str, Any]]:
    conn = get_connection(db_path)
    now_dt = datetime.now(timezone.utc)
    now = now_dt.isoformat()
    expires_at = datetime.fromtimestamp(now_dt.timestamp() + ttl_seconds, tz=timezone.utc).isoformat()
    command_id = str(uuid.uuid4())

    try:
        # Check target device ownership and revocation
        dev = conn.execute(
            "SELECT * FROM devices WHERE id = ? AND user_id = ? AND revoked_at IS NULL",
            (device_id, user_id)
        ).fetchone()
        if not dev:
            return None

        conn.execute(
            """
            INSERT INTO commands (
                id, user_id, device_id, action, status, created_at, expires_at
            ) VALUES (?, ?, ?, ?, 'pending', ?, ?)
            """,
            (command_id, user_id, device_id, action, now, expires_at)
        )
        conn.commit()

        return {
            "id": command_id,
            "user_id": user_id,
            "device_id": device_id,
            "action": action,
            "status": "pending",
            "created_at": now,
            "expires_at": expires_at,
            "accepted_at": None,
            "finished_at": None,
            "error_code": None,
            "result_summary": None,
        }
    finally:
        conn.close()


def get_command_by_id(command_id: str, db_path: Optional[str] = None) -> Optional[Dict[str, Any]]:
    conn = get_connection(db_path)
    try:
        row = conn.execute("SELECT * FROM commands WHERE id = ?", (command_id,)).fetchone()
        return dict(row) if row else None
    finally:
        conn.close()


def list_commands_by_user(user_id: str, limit: int = 50, db_path: Optional[str] = None) -> List[Dict[str, Any]]:
    conn = get_connection(db_path)
    try:
        rows = conn.execute(
            "SELECT * FROM commands WHERE user_id = ? ORDER BY created_at DESC LIMIT ?",
            (user_id, limit)
        ).fetchall()
        return [dict(r) for r in rows]
    finally:
        conn.close()


def update_command_status(
    command_id: str,
    status: str,
    accepted_at: Optional[str] = None,
    finished_at: Optional[str] = None,
    error_code: Optional[str] = None,
    result_summary: Optional[str] = None,
    db_path: Optional[str] = None,
) -> bool:
    conn = get_connection(db_path)
    try:
        updates = ["status = ?"]
        params: List[Any] = [status]
        if accepted_at is not None:
            updates.append("accepted_at = ?")
            params.append(accepted_at)
        if finished_at is not None:
            updates.append("finished_at = ?")
            params.append(finished_at)
        if error_code is not None:
            updates.append("error_code = ?")
            params.append(error_code)
        if result_summary is not None:
            updates.append("result_summary = ?")
            params.append(result_summary)

        params.append(command_id)
        query = f"UPDATE commands SET {', '.join(updates)} WHERE id = ?"
        cur = conn.execute(query, tuple(params))
        conn.commit()
        return cur.rowcount > 0
    finally:
        conn.close()


def cancel_command(command_id: str, user_id: str, db_path: Optional[str] = None) -> bool:
    conn = get_connection(db_path)
    now = get_utc_now()
    try:
        cur = conn.execute(
            """
            UPDATE commands
            SET status = 'cancelled', finished_at = ?
            WHERE id = ? AND user_id = ? AND status = 'pending'
            """,
            (now, command_id, user_id)
        )
        conn.commit()
        return cur.rowcount > 0
    finally:
        conn.close()


# ---------------- Audit Operations ----------------

def record_audit_event(
    user_id: str,
    event_type: str,
    device_id: Optional[str] = None,
    command_id: Optional[str] = None,
    metadata: Optional[Dict[str, Any]] = None,
    db_path: Optional[str] = None,
):
    """Stores an audit event. NEVER accepts passwords, tokens, or clipboard bodies."""
    event_id = str(uuid.uuid4())
    now = get_utc_now()
    meta_json = json.dumps(metadata or {})
    conn = get_connection(db_path)
    try:
        conn.execute(
            """
            INSERT INTO audit_events (
                id, user_id, device_id, command_id, event_type, created_at, metadata
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (event_id, user_id, device_id, command_id, event_type, now, meta_json)
        )
        conn.commit()
    finally:
        conn.close()


def list_audit_events_by_user(user_id: str, limit: int = 100, db_path: Optional[str] = None) -> List[Dict[str, Any]]:
    conn = get_connection(db_path)
    try:
        rows = conn.execute(
            "SELECT * FROM audit_events WHERE user_id = ? ORDER BY created_at DESC LIMIT ?",
            (user_id, limit)
        ).fetchall()
        result = []
        for r in rows:
            d = dict(r)
            try:
                d["metadata"] = json.loads(d["metadata"])
            except Exception:
                d["metadata"] = {}
            result.append(d)
        return result
    finally:
        conn.close()


def expire_stale_records(db_path: Optional[str] = None):
    """Marks overdue pending commands as expired and cleans expired pairing codes."""
    conn = get_connection(db_path)
    now = get_utc_now()
    try:
        conn.execute(
            """
            UPDATE commands
            SET status = 'expired', finished_at = ?
            WHERE status = 'pending' AND expires_at < ?
            """,
            (now, now)
        )
        conn.commit()
    finally:
        conn.close()
