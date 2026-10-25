---
name: firebase-iot-ops
description: >-
  Workflows and procedures for managing the World of IT (world_of_iot) Firebase Realtime Database,
  Firebase Authentication, Flutter client options, and Python Linux desktop agent (clipboard sync
  and remote allowlisted commands like shutdown, restart, sleep, health_check).
---

# World of IT — Firebase & Agent Operations Skill

Use this skill when linking a live Firebase project, deploying `database.rules.json`, running the Firebase Local Emulator Suite, or testing real-time clipboard sync and remote commands between the Flutter client and Linux desktop agent.

## 1. Environment Paths
- **Firebase CLI**: `/home/user/.nvm/versions/node/v22.23.2/bin/firebase`
- **Flutter / Dart SDK**: `/home/user/flutter/bin/flutter` and `/home/user/flutter/bin/dart`
- **FlutterFire CLI**: `/home/user/.pub-cache/bin/flutterfire`
- **Python Venv**: `.venv/bin/python3` and `.venv/bin/pytest`

## 2. Connecting to a Live Firebase Project
1. Ensure Firebase CLI is authenticated (`firebase login`).
2. Link this repo to the target Firebase project ID:
   - Update [.firebaserc](file:///home/user/Extras/Flutter-Projects-Backup/working/world_of_iot/.firebaserc) with the project ID.
   - Run `flutterfire configure --project=<project-id>` to regenerate [lib/firebase_options.dart](file:///home/user/Extras/Flutter-Projects-Backup/working/world_of_iot/lib/firebase_options.dart).
3. Deploy the Realtime Database Security Rules:
   - `firebase deploy --only database` (deploys [database.rules.json](file:///home/user/Extras/Flutter-Projects-Backup/working/world_of_iot/database.rules.json)).

## 3. Running the Linux Desktop Agent (`agent/agent.py`)
- **Dry-Run / Local Emulator Mode**:
  ```bash
  .venv/bin/python3 agent/agent.py --firebase-url http://127.0.0.1:9000 --uid <user-uid> --device-id <device-id> --dry-run
  ```
- **Live Firebase Realtime Database Mode**:
  ```bash
  .venv/bin/python3 agent/agent.py --firebase-url https://<project-id>-default-rtdb.firebaseio.com --uid <user-uid> --device-id <device-id> --auth-token <id-token>
  ```

## 4. Verification Suite
Run `.venv/bin/python3 .gravitas/verify_all.py` to execute all 12 Python unit/integration tests, 6 Flutter widget/model tests, and `dart analyze`.
