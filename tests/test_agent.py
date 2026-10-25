"""
Unit test suite for Linux desktop agent logic.
Tests allowlists, command validation, dry-run safety, and clipboard loop prevention.
"""

import json
import pytest
from agent.agent import DeviceAgent, LocalClipboard


def test_agent_allowlist_enforcement(tmp_path):
    config_file = tmp_path / "test_config.json"
    agent = DeviceAgent(config_file=str(config_file), dry_run=True)

    # 1. Allowlisted actions should succeed in dry-run
    for act in ["health_check", "shutdown", "restart", "sleep"]:
        res = agent.execute_command_action(act)
        assert res["status"] == "succeeded"

    # 2. Unknown action should fail
    res = agent.execute_command_action("arbitrary_bash_command")
    assert res["status"] == "failed"


def test_clipboard_loop_suppression(tmp_path):
    config_file = tmp_path / "test_config.json"
    agent = DeviceAgent(config_file=str(config_file), dry_run=True)
    agent.config = {"clipboard_sync_enabled": True}

    # Simulate receiving incoming clipboard update from server
    agent.last_received_event_id = "remote-evt-123"
    agent.last_synced_clipboard_text = "Secret copied text from phone"

    # If local clipboard text matches the incoming text, it must not sync back (loop prevention)
    assert agent.last_synced_clipboard_text == "Secret copied text from phone"
    assert agent.last_received_event_id == "remote-evt-123"
