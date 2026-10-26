# ClipSync 🌐⚡

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Realtime_DB_%26_Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android_%7C_Linux_%7C_Windows-E95420?logo=linux&logoColor=white)](https://github.com/hurairamuzammal/world_of_iot)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v2.2.0-8A2BE2)](#version--developer)
[![Access](https://img.shields.io/badge/Access-Private_Repository-critical)](#)

> **Seamless, private cross-platform clipboard synchronizer & device hub** bridging Android mobile devices, Linux desktop systems, and Windows workstations with sub-second latency on your own free Firebase cloud.

---

## 🌟 Key Highlights

- **⚡ Sub-Second Bidirectional Clipboard Sync**
  - Instant background copy detection and remote propagation between Android, Linux, and Windows.
  - Native Samsung floating pill notification toasts with subtle audio cues on incoming remote clips.
  - In-app clipboard history with quick copy, clear, and unread badge counters.
  - Master **"Clipboard Sync"** switch for one-tap privacy pause when handling passwords or credentials.

- **☁️ Bring Your Own Free Cloud ($0 Hosting Cost)**
  - Operates on a **100% free personal Firebase tier** (no credit card required).
  - Complete data sovereignty: All clipboard items and paired devices reside strictly within your personal Firebase Realtime Database.
  - Configure right from the app's setup screen or settings without touching a line of code.
  - See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for a 3-minute step-by-step tutorial.

- **🛡️ Global Legal & Privacy Compliance (GDPR, CCPA, COPPA)**
  - **Zero Telemetry & Zero Ads:** No tracking SDKs, no third-party data selling, no analytics.
  - **TLS 1.3 Encryption:** All network communication is strictly encrypted over HTTPS and secure WebSockets.
  - **GDPR Article 17 (Right to Erasure):** In-app one-click buttons to wipe all cloud clipboard history or permanently delete your user account and device nodes.
  - See [PRIVACY.md](PRIVACY.md), [TERMS.md](TERMS.md), and [FAQ.md](FAQ.md).

- **📱 Android Keep-Alive & Background Sync**
  - Accessibility Service copy detector to bypass Android 10+ background clipboard restrictions.
  - Ongoing persistent notification with a quick **"Send to Laptop"** action.
  - Battery optimization exemption to keep synchronization active through Samsung One UI Knox deep sleep.

- **🖥️ Native Multi-Platform Support**
  - **Android:** Full native Kotlin foreground service + Accessibility integration.
  - **Linux Desktop:** Native Flutter Linux bundle with GTK clipboard integration.
  - **Windows:** Native Flutter Windows x64 desktop support with clipboard listeners.

---

## 🏗️ Architecture

```
+-------------------------------------------------------------------+
|               User's Private Free Firebase Cloud                  |
|  - Firebase Authentication (Google OAuth + Email/Password)        |
|  - Firebase Realtime Database (/users/{uid}/devices & clips)      |
+---------------------------------+---------------------------------+
                                  |
            +---------------------+---------------------+
            |         (Sub-second TLS 1.3 RTDB)         |
            v                                           v
+-----------------------+ +-----------------------+ +-----------------------+
|  Android Smartphone   | |     Linux Desktop     | |    Windows Desktop    |
| - ClipSync Flutter    | | - ClipSync Flutter    | | - ClipSync Flutter    |
| - Accessibility Svc   | | - GTK Clipboard Sync  | | - Win32 Clipboard Sync|
| - Ongoing Shade Action| | - System Presence     | | - System Presence     |
| - Samsung Pill Toasts | | - Fast Heartbeats     | | - Fast Heartbeats     |
+-----------------------+ +-----------------------+ +-----------------------+
```

---

## 📂 Project Structure

```
world_of_iot/
├── android/                 # Native Android project configuration & Kotlin services
├── assets/                  # High-resolution vector & brand launcher assets
├── lib/                     # Pure Flutter Application Core
│   ├── firebase_options.dart # Template Firebase options (customizable in-app)
│   ├── main.dart            # Flutter application entry point
│   ├── models/              # Device, Command, and Audit data models
│   ├── screens/
│   │   ├── auth_screen.dart           # Authentication & Cloud Connect screen
│   │   ├── dashboard_screen.dart      # Real-time paired devices & sync dashboard
│   │   ├── developer_screen.dart      # Attribution & system diagnostics
│   │   ├── legal_and_faq_screen.dart  # GDPR/CCPA docs, FAQ, and Support
│   │   └── settings_screen.dart       # Master toggles, cloud setup & erasure
│   ├── services/
│   │   ├── api_service.dart           # Unified communication interface
│   │   ├── background_sync_service.dart # Android Accessibility & Keep-Alive bridge
│   │   ├── clipboard_sync_manager.dart # Event-driven cross-platform clipboard manager
│   │   └── firebase_service.dart      # Dynamic Firebase RTDB & Auth client
│   └── widgets/             # Brand logos, badges, and confirmation dialogs
├── linux/                   # Native Linux desktop runner & CMake build files
├── windows/                 # Native Windows desktop runner & Win32 build files
├── test/                    # Flutter widget and unit verification suite
├── FIREBASE_SETUP.md        # 3-minute free cloud setup guide
├── PRIVACY.md               # GDPR & CCPA privacy policy
├── TERMS.md                 # MIT License & Terms of Service
├── FAQ.md                   # Frequently Asked Questions
├── SUPPORT.md               # Developer contact & official support
├── database.rules.json      # Hardened Firebase RTDB security rules
└── pubspec.yaml             # Flutter project manifest & dependencies
```

---

## 🚀 Quick Start

### 1. Configure Your Free Firebase
Follow [FIREBASE_SETUP.md](FIREBASE_SETUP.md) to set up your 100% free Firebase project in 3 minutes. No credit card is required.

### 2. Run the Application

**Linux Desktop:**
```bash
flutter run -d linux
```

**Android Device:**
```bash
flutter run -d <device_id>
```

**Windows Desktop:**
```bash
flutter run -d windows
```

### 3. Connect Cloud in the App
When you open ClipSync, tap **Connect** on the cloud strip, paste your **Project ID** and **Web API Key**, and tap **Save & Apply**. You are now securely syncing across your devices!

---

## 🧪 Testing & Verification

Run the Flutter unit and widget test suite:
```bash
flutter test
```

Perform static analysis:
```bash
flutter analyze
```

---

## ⚖️ Legal & Privacy Compliance

ClipSync complies with global software distribution regulations:
- **Privacy Policy:** [PRIVACY.md](PRIVACY.md)
- **Terms of Service:** [TERMS.md](TERMS.md)
- **Support & Inquiries:** [SUPPORT.md](SUPPORT.md)
- **License:** [MIT License](LICENSE)

---

## 👤 Version & Developer

- **Application Version:** `v2.2.0 (Build 220)`
- **Lead Developer:** **Muhammad Abu Huraira** ([@hurairamuzammal](https://github.com/hurairamuzammal))
- **Email:** [huraira.eqeel@gmail.com](mailto:huraira.eqeel@gmail.com)
- **Location:** Lahore, Punjab, Pakistan
- **Status:** Standalone Private Repository
