# ClipSync 🌐⚡

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Realtime_DB_%26_Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white)](https://python.org)
[![Platform](https://img.shields.io/badge/Platform-Android_%7C_Linux-E95420?logo=linux&logoColor=white)](https://ubuntu.com)
[![Version](https://img.shields.io/badge/Version-v2.2.0-8A2BE2)](#version--developer)
[![Access](https://img.shields.io/badge/Access-Private_Repository-critical)](#)

> **Seamless real-time device hub & cross-platform clipboard synchronizer** bridging Android mobile devices and Linux desktop systems with sub-second latency via Firebase Realtime Database.

---

## 🌟 Overview

**ClipSync** is an ecosystem designed to unify your mobile and desktop workflows. It seamlessly bridges Linux workstations (e.g. ThinkPad) with Android smartphones (e.g. Samsung Galaxy) through bidirectional, sub-second clipboard synchronization, peer presence tracking, remote device telemetry, and allowlisted device management commands.

Built with a **Flutter cross-platform client**, a lightweight **Python background daemon** (`agent.py`) with a native desktop tray indicator (`sni_tray.py`), and backed by **Firebase Realtime Database (RTDB)** and **Firebase Auth**.

---

## ✨ Key Features

- **⚡ Sub-Second Bidirectional Clipboard Sync**
  - Instant background copy detection and remote propagation between Linux and Android.
  - Native Android floating pill notification toasts with subtle audio cues on incoming remote clips.
  - In-app clipboard history with quick copy, clear, and unread badge counters.

- **🐧 Native Linux Desktop Integration**
  - Lightweight Python daemon (`agent/agent.py`) running seamlessly as a `systemd` user service (`world-of-iot-agent.service`).
  - Desktop status tray (`sni_tray.py`) with dynamic monochrome clipboard icon and peer online/offline indicators.
  - One-click tray actions: *Sync Clipboard Now*, *Open ClipSync*, *Toggle Auto-Sync*, and *Restart Agent*.

- **📱 Smart Peer Device Filtering**
  - Automatic peer device isolation: Each device monitors and displays the status of paired peer devices without self-referential clutter.
  - Live heartbeat indicators showing peer online status, IP address, and last-seen timestamps.

- **🔒 Enterprise-Grade Security & Authentication**
  - Multi-provider authentication supporting **OAuth Google Sign-In** and **Email & Password**.
  - Secure self-service password reset workflow restricted exclusively to email accounts.
  - Per-user path isolation in Firebase Realtime Database rules (`/users/$uid/*`) ensuring zero cross-tenant data leaks.
  - Sensitive tokens and runtime credentials strictly isolated in git-ignored local configurations.

- **🎨 Modern Minimalist UI & Brand Identity**
  - Elegant pastel violet palette with modern Material 3 typography and dark mode accents.
  - Dedicated Developer & App Info view (`DeveloperScreen`) highlighting version metadata (`v2.1.0`) and engineering attribution.
  - Custom launcher and status icons optimized for Android adaptive icons and Linux desktop bars.

---

## 🏗️ Architecture

```
+-------------------------------------------------------------+
|                     Firebase Cloud Backend                  |
|  - Firebase Authentication (Google OAuth + Email/Password)  |
|  - Firebase Realtime Database (/users/{uid}/devices & clips)|
+------------------------------+------------------------------+
                               |
               +---------------+---------------+
               | (Sub-second RTDB WebSockets)  |
               v                               v
+-----------------------------+ +-----------------------------+
|     Linux Desktop Client    | |    Android Mobile Device    |
|  - Flutter Desktop App      | |  - Flutter Mobile App       |
|  - Python Agent (agent.py)  | |  - Samsung Floating Toast   |
|  - System Tray (pystray)    | |  - Native Audio Feedback    |
|  - Wayland / X11 Clipboard  | |  - Peer Filtering View      |
|  - Systemd User Service     | |  - Fast Reconnect Daemon    |
+-----------------------------+ +-----------------------------+
```

---

## 📂 Project Structure

```
world_of_iot/
├── .agents/                 # Custom Agentic development kits & skill definitions
├── .gravitas/               # Automated multi-suite verification harness
├── agent/                   # Linux Desktop Background Agent
│   ├── agent.py             # Core Python clipboard sync & command daemon
│   ├── sni_tray.py          # Native Linux system tray indicator (pystray)
│   ├── setup_linux_autostart.py # Systemd user service installer
│   ├── requirements.txt     # Python agent dependencies
│   └── world-of-iot-agent.service # Systemd service unit definition
├── android/                 # Native Android project configuration & Gradle scripts
├── assets/
│   └── icons/               # App icons & vector assets
├── backend/                 # Optional self-hosted REST/WebSocket backend alternative
│   ├── main.py              # FastAPI service
│   ├── models.py            # Pydantic schemas
│   ├── database.py          # SQLite persistence layer
│   └── security.py          # Token verification & cryptography
├── deploy/                  # Docker & Caddy deployment configs
├── lib/                     # Flutter Application Core
│   ├── firebase_options.dart # Firebase client options
│   ├── main.dart            # Flutter application entry point
│   ├── models/              # Device and Clipboard data models
│   ├── screens/             # UI Screens (Auth, Home, Devices, Clipboard, Developer)
│   ├── services/            # Firebase, Clipboard, and Settings services
│   └── widgets/             # Reusable UI components & custom cards
├── test/                    # Flutter unit & widget tests
├── tests/                   # Python backend & desktop agent pytest suite
├── database.rules.json      # Production Firebase Realtime Database security rules
├── firebase.json            # Firebase CLI project configuration
├── device_config.example.json # Template for local desktop agent credentials
└── pubspec.yaml             # Flutter dependencies & metadata
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: `>= 3.13.1` ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: Included with Flutter
- **Python**: `>= 3.10`
- **Linux Tools** (for Linux agent): `xclip` or `wl-clipboard`, `libappindicator3-1`
- **Android Device**: Android 8.0+ (API 26+) with USB/Wi-Fi Debugging enabled

### 1. Repository Setup

```bash
git clone https://github.com/hurairamuzammal/world_of_iot.git
cd world_of_iot
flutter pub get
```

### 2. Configure Desktop Agent

Create your local agent configuration file from the provided template:

```bash
cp device_config.example.json device_config.json
```

Edit `device_config.json` with your Firebase project credentials and device identifier:

```json
{
  "backend_type": "firebase",
  "firebase_rtdb_url": "https://<your-project-id>-default-rtdb.firebaseio.com",
  "user_id": "<your-firebase-user-uid>",
  "device_id": "thinkpad_linux_01",
  "display_name": "ThinkPad Linux",
  "clipboard_sync_enabled": true,
  "firebase_id_token": "<your-firebase-id-token>",
  "firebase_refresh_token": "<your-firebase-refresh-token>",
  "firebase_api_key": "<your-firebase-web-api-key>"
}
```

> [!NOTE]
> `device_config.json` is strictly ignored by version control to prevent credential leakage.

### 3. Run Flutter Application

**On Linux Desktop:**
```bash
flutter run -d linux
```

**On Android Device:**
```bash
flutter run -d <device_id>
```

**Build Release APK:**
```bash
flutter build apk --release
```

### 4. Enable Linux Background Daemon & System Tray

Set up the Python virtual environment and install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r agent/requirements.txt
```

Register and enable the agent as an automatic `systemd` user service:

```bash
python3 agent/setup_linux_autostart.py
systemctl --user status world-of-iot-agent.service
```

---

## 🧪 Testing & Verification

ClipSync includes an end-to-end verification harness ensuring code quality, security rules integrity, and platform compatibility.

Run the full verification suite:

```bash
python3 .gravitas/verify_all.py
```

Or run individual test runners:

```bash
# Flutter widget & unit tests
flutter test

# Dart static analysis
flutter analyze

# Python agent & backend pytest suite
pytest tests/ -v
```

---

## 🔒 Security Policy

- **Per-User Isolation**: All device heartbeats and clipboard payloads are compartmentalized under `/users/{uid}/` paths in Firebase Realtime Database.
- **Client Security Rules**: Unauthenticated or cross-user reads and writes are rejected by `database.rules.json`.
- **Command Allowlisting**: Remote device operations strictly execute allowlisted, sanitized commands (`shutdown`, `restart`, `sleep`, `health_check`).
- **No Secret Check-ins**: `.gitignore` comprehensively guards against committing local tokens, Android keystores, or active user sessions.

---

## 👤 Version & Developer

- **Application Version**: `v2.1.0 (Build 210)`
- **Lead Developer**: **Muhammad Abu Huraira** ([@hurairamuzammal](https://github.com/hurairamuzammal))
- **Email**: [huraira.eqeel@gmail.com](mailto:huraira.eqeel@gmail.com)
- **Status**: Private Repository
