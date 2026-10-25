"""
Tests for Firebase Realtime Database structure, rules, and Agent Firebase client.
"""

import json
from pathlib import Path
import pytest
from agent.agent import DeviceAgent


def test_firebase_rules_validity():
    rules_path = Path("database.rules.json")
    assert rules_path.exists(), "database.rules.json must exist"

    with open(rules_path, "r", encoding="utf-8") as f:
        rules = json.load(f)

    assert "rules" in rules
    assert "users" in rules["rules"]
    assert "$uid" in rules["rules"]["users"]
    user_rules = rules["rules"]["users"]["$uid"]

    # Verify per-user isolation
    assert ".read" in user_rules
    assert "auth.uid == $uid" in user_rules[".read"]
    assert "auth.uid == $uid" in user_rules[".write"]

    # Verify entities
    assert "devices" in user_rules
    assert "commands" in user_rules
    assert "clipboardEvents" in user_rules
    assert "pairingRequests" in user_rules


def test_firebase_config_validity():
    rc_path = Path(".firebaserc")
    assert rc_path.exists()
    with open(rc_path, "r", encoding="utf-8") as f:
        rc = json.load(f)
    assert rc["projects"]["default"] in ("world-of-iot-hub", "world-of-it-app")

    fb_path = Path("firebase.json")
    assert fb_path.exists()
    with open(fb_path, "r", encoding="utf-8") as f:
        fb = json.load(f)
    assert fb["database"]["rules"] == "database.rules.json"
    assert fb["emulators"]["database"]["port"] == 9000


def test_agent_handles_firebase_command(tmp_path):
    config_file = tmp_path / "firebase_config.json"
    agent = DeviceAgent(config_file=str(config_file), dry_run=True)

    # Allowlisted action
    res = agent.execute_command_action("health_check")
    assert res["status"] == "succeeded"
    assert "Health OK" in res["summary"]

    # Power action (dry-run safe)
    res = agent.execute_command_action("restart")
    assert res["status"] == "succeeded"

    # Non-allowlisted action must fail
    res = agent.execute_command_action("bash -c malicious")
    assert res["status"] == "failed"
