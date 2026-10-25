#!/usr/bin/env python3
"""
Generates and installs the systemd user service and XDG autostart desktop entry
for the World of IT Linux Agent + Top Bar Indicator so it automatically launches
on login/boot and reconnects whenever Wi-Fi is available.
"""

import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PYTHON_BIN = REPO_ROOT / ".venv/bin/python3"
AGENT_SCRIPT = REPO_ROOT / "agent/agent.py"
CONFIG_FILE = REPO_ROOT / "device_config.json"

SERVICE_CONTENT = f"""[Unit]
Description=World of IT Seamless Clipboard & Command Sync Agent
After=network-online.target graphical-session.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory={REPO_ROOT}
ExecStart={PYTHON_BIN} {AGENT_SCRIPT} --config {CONFIG_FILE}
Restart=always
RestartSec=3
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=default.target
"""


def main():
    service_path = REPO_ROOT / "agent/world-of-iot-agent.service"
    service_path.write_text(SERVICE_CONTENT, encoding="utf-8")
    print(f"Generated systemd unit template at: {service_path}")

    systemd_user_dir = Path.home() / ".config/systemd/user"
    systemd_user_dir.mkdir(parents=True, exist_ok=True)
    target_service = systemd_user_dir / "world-of-iot-agent.service"
    target_service.write_text(SERVICE_CONTENT, encoding="utf-8")

    subprocess.run(["systemctl", "--user", "daemon-reload"], check=False)
    subprocess.run(["systemctl", "--user", "enable", "world-of-iot-agent.service"], check=False)
    print("Enabled systemd user service: world-of-iot-agent.service (auto-starts on boot/login)")


if __name__ == "__main__":
    main()
