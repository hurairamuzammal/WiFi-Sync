"""
Automated unit and integration test suite for World of IT backend.
Tests Auth, Device Management, Pairing, Commands, and Security Invariants.
"""

import os
import pytest
from fastapi.testclient import TestClient

# Use a test database path
os.environ["DATABASE_PATH"] = "test_world_of_it.db"

from backend.config import settings
from backend.main import app
from backend.database import init_db

client = TestClient(app)

TEST_DB = "test_world_of_it.db"

@pytest.fixture(autouse=True)
def setup_test_db():
    settings.DATABASE_PATH = TEST_DB
    if os.path.exists(TEST_DB):
        os.remove(TEST_DB)
    init_db(TEST_DB)
    yield
    if os.path.exists(TEST_DB):
        os.remove(TEST_DB)


def test_health_check():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "healthy"


def test_auth_signup_and_login():
    # 1. Sign up user
    signup_resp = client.post(
        "/api/v1/auth/signup",
        json={"email": "alice@example.com", "password": "supersecretpassword"},
    )
    assert signup_resp.status_code == 200
    token_data = signup_resp.json()
    assert "access_token" in token_data
    assert token_data["email"] == "alice@example.com"
    token = token_data["access_token"]

    # 2. Reject duplicate email
    dup_resp = client.post(
        "/api/v1/auth/signup",
        json={"email": "alice@example.com", "password": "anotherpassword"},
    )
    assert dup_resp.status_code == 400

    # 3. Successful login
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"email": "alice@example.com", "password": "supersecretpassword"},
    )
    assert login_resp.status_code == 200
    assert "access_token" in login_resp.json()

    # 4. Failed login
    bad_resp = client.post(
        "/api/v1/auth/login",
        json={"email": "alice@example.com", "password": "wrongpassword"},
    )
    assert bad_resp.status_code == 401

    # 5. Access protected /me
    me_resp = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert me_resp.status_code == 200
    assert me_resp.json()["email"] == "alice@example.com"


def test_device_lifecycle():
    # Setup user
    signup = client.post(
        "/api/v1/auth/signup",
        json={"email": "bob@example.com", "password": "password123"},
    )
    token = signup.json()["access_token"]
    auth_header = {"Authorization": f"Bearer {token}"}

    # 1. Register device
    reg_resp = client.post(
        "/api/v1/devices",
        json={"display_name": "Bob Linux Box", "platform": "linux", "agent_version": "1.0.0"},
        headers=auth_header,
    )
    assert reg_resp.status_code == 200
    dev = reg_resp.json()
    device_id = dev["id"]
    assert "device_secret" in dev
    assert dev["display_name"] == "Bob Linux Box"
    assert dev["status"] == "offline"

    # 2. List devices
    list_resp = client.get("/api/v1/devices", headers=auth_header)
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1

    # 3. Update device (rename and toggle clipboard sync)
    patch_resp = client.patch(
        f"/api/v1/devices/{device_id}",
        json={"display_name": "Bob Workstation", "clipboard_sync_enabled": True},
        headers=auth_header,
    )
    assert patch_resp.status_code == 200
    assert patch_resp.json()["display_name"] == "Bob Workstation"
    assert patch_resp.json()["clipboard_sync_enabled"] is True

    # 4. Revoke device
    revoke_resp = client.delete(f"/api/v1/devices/{device_id}", headers=auth_header)
    assert revoke_resp.status_code == 200

    # 5. Verify device no longer listed in active devices
    active_resp = client.get("/api/v1/devices", headers=auth_header)
    assert len(active_resp.json()) == 0


def test_pairing_code_flow():
    # Setup user
    signup = client.post(
        "/api/v1/auth/signup",
        json={"email": "carol@example.com", "password": "password123"},
    )
    token = signup.json()["access_token"]
    auth_header = {"Authorization": f"Bearer {token}"}

    # 1. Request 6-digit pairing code
    code_resp = client.post("/api/v1/devices/pair/request", headers=auth_header)
    assert code_resp.status_code == 200
    code = code_resp.json()["code"]
    assert len(code) == 6

    # 2. Claim pairing code from agent
    claim_resp = client.post(
        "/api/v1/devices/pair/claim",
        json={
            "code": code,
            "display_name": "Carol Remote Laptop",
            "platform": "linux",
            "agent_version": "1.0.0",
        },
    )
    assert claim_resp.status_code == 200
    dev = claim_resp.json()
    assert dev["display_name"] == "Carol Remote Laptop"
    assert "device_secret" in dev

    # 3. Claiming the same code again should fail
    dup_claim = client.post(
        "/api/v1/devices/pair/claim",
        json={
            "code": code,
            "display_name": "Carol Second Laptop",
            "platform": "linux",
            "agent_version": "1.0.0",
        },
    )
    assert dup_claim.status_code == 400


def test_command_dispatch_and_allowlist():
    # Setup user and device
    signup = client.post(
        "/api/v1/auth/signup",
        json={"email": "dave@example.com", "password": "password123"},
    )
    token = signup.json()["access_token"]
    auth_header = {"Authorization": f"Bearer {token}"}

    reg_resp = client.post(
        "/api/v1/devices",
        json={"display_name": "Dave Server", "platform": "linux"},
        headers=auth_header,
    )
    device_id = reg_resp.json()["id"]

    # 1. Dispatch allowlisted command (health_check)
    cmd_resp = client.post(
        "/api/v1/commands",
        json={"device_id": device_id, "action": "health_check", "ttl_seconds": 60},
        headers=auth_header,
    )
    assert cmd_resp.status_code == 200
    cmd = cmd_resp.json()
    assert cmd["action"] == "health_check"
    assert cmd["status"] in ["pending", "unconfirmed"]

    # 2. Dispatch allowlisted shutdown command
    shutdown_resp = client.post(
        "/api/v1/commands",
        json={"device_id": device_id, "action": "shutdown", "ttl_seconds": 60},
        headers=auth_header,
    )
    assert shutdown_resp.status_code == 200
    assert shutdown_resp.json()["action"] == "shutdown"

    # 3. Reject non-allowlisted / arbitrary shell action
    bad_cmd = client.post(
        "/api/v1/commands",
        json={"device_id": device_id, "action": "rm -rf /", "ttl_seconds": 60},
        headers=auth_header,
    )
    assert bad_cmd.status_code == 422  # Pydantic enum validation failure

    # 4. View command history
    hist_resp = client.get("/api/v1/commands", headers=auth_header)
    assert hist_resp.status_code == 200
    assert len(hist_resp.json()) >= 2


def test_audit_log_recording():
    signup = client.post(
        "/api/v1/auth/signup",
        json={"email": "eve@example.com", "password": "password123"},
    )
    token = signup.json()["access_token"]
    auth_header = {"Authorization": f"Bearer {token}"}

    audit_resp = client.get("/api/v1/audit", headers=auth_header)
    assert audit_resp.status_code == 200
    events = audit_resp.json()
    assert len(events) >= 1
    assert any(e["event_type"] == "user_signup" for e in events)
