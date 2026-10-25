"""
End-to-End WebSocket and Agent lifecycle integration test.
Tests live WebSocket connection, heartbeats, command dispatch, and result acknowledgement.
"""

import asyncio
import json
import os
import pytest
from starlette.testclient import TestClient

os.environ["DATABASE_PATH"] = "test_e2e_ws.db"

from backend.config import settings
from backend.main import app
from backend.database import init_db, get_device_by_id, get_command_by_id

client = TestClient(app)

TEST_E2E_DB = "test_e2e_ws.db"

@pytest.fixture(autouse=True)
def setup_test_db():
    settings.DATABASE_PATH = TEST_E2E_DB
    if os.path.exists(TEST_E2E_DB):
        os.remove(TEST_E2E_DB)
    init_db(TEST_E2E_DB)
    yield
    if os.path.exists(TEST_E2E_DB):
        os.remove(TEST_E2E_DB)


def test_agent_websocket_e2e_lifecycle():
    # 1. Create user and register device
    signup = client.post(
        "/api/v1/auth/signup",
        json={"email": "e2e@example.com", "password": "password123"},
    )
    token = signup.json()["access_token"]
    auth_header = {"Authorization": f"Bearer {token}"}

    reg_resp = client.post(
        "/api/v1/devices",
        json={"display_name": "E2E Machine", "platform": "linux"},
        headers=auth_header,
    )
    dev = reg_resp.json()
    device_id = dev["id"]
    device_secret = dev["device_secret"]

    # 2. Connect agent over WebSocket
    with client.websocket_connect(f"/ws/agent/{device_id}?secret={device_secret}") as ws:
        # Check that device is now reported online
        get_dev = client.get(f"/api/v1/devices/{device_id}", headers=auth_header)
        assert get_dev.json()["status"] == "online"

        # 3. Send heartbeat from agent
        ws.send_text(json.dumps({"type": "heartbeat", "timestamp": "2026-10-21T12:00:00Z"}))
        resp = ws.receive_json()
        assert resp["type"] == "heartbeat_ack"

        # 4. Dispatch a command via HTTP while agent is connected
        cmd_resp = client.post(
            "/api/v1/commands",
            json={"device_id": device_id, "action": "health_check", "ttl_seconds": 60},
            headers=auth_header,
        )
        assert cmd_resp.status_code == 200
        cmd_id = cmd_resp.json()["id"]

        # 5. Agent receives the dispatched command over WebSocket
        incoming_cmd = ws.receive_json()
        assert incoming_cmd["type"] == "command_dispatch"
        assert incoming_cmd["command"]["id"] == cmd_id
        assert incoming_cmd["command"]["action"] == "health_check"

        # 6. Agent sends command_ack
        ws.send_text(json.dumps({
            "type": "command_ack",
            "command_id": cmd_id,
        }))

        # 7. Agent sends command_result
        ws.send_text(json.dumps({
            "type": "command_result",
            "command_id": cmd_id,
            "status": "succeeded",
            "result_summary": "Health OK: simulated load=0.10",
        }))

        # Send heartbeat to flush WebSocket queue
        ws.send_text(json.dumps({"type": "heartbeat", "timestamp": "2026-10-21T12:00:01Z"}))
        ack = ws.receive_json()
        assert ack["type"] == "heartbeat_ack"

        # 8. Verify command status is updated in backend
        check_cmd = client.get(f"/api/v1/commands/{cmd_id}", headers=auth_header)
        assert check_cmd.status_code == 200
        cmd_data = check_cmd.json()
        assert cmd_data["status"] == "succeeded"
        assert "Health OK" in cmd_data["result_summary"]

    # 9. After WebSocket disconnects, device presence reflects offline
    after_disconnect = client.get(f"/api/v1/devices/{device_id}", headers=auth_header)
    assert after_disconnect.json()["status"] == "offline"
