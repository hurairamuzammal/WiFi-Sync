# World of IT: Project Scope

## 1. Product vision

World of IT is a cross-platform device management and synchronization app. A user signs in, registers their devices, and manages them from one dashboard. Devices communicate through an internet-accessible server, so they do not need to be connected to the same Wi-Fi network.

## 2. Goals

- Provide one account for a user's connected devices.
- Show device identity and online/offline status.
- Synchronize text clipboard content between authorized devices.
- Request supported system actions such as shutdown, restart, and sleep.
- Report whether commands are pending, acknowledged, successful, failed, or timed out.
- Keep communication authenticated and encrypted.
- Use Firebase managed services so the project does not consume Oracle compute or require an always-on custom server.

## 3. Target platforms

### MVP target

- Flutter app: Android and Linux desktop UI.
- Device agent: Linux desktop, initially.
- Backend services: Firebase Authentication and Firebase Realtime Database.
- Authorization: Firebase Security Rules, with Cloud Functions for trusted pairing/revocation operations if required.
- No Oracle VM or custom FastAPI/WebSocket server in the MVP.

### Later expansion

- Windows and macOS desktop agents.
- iOS app, within iOS background execution and clipboard restrictions.
- Android device-agent features, within Android background and clipboard restrictions.

Flutter's cross-platform UI does not make operating-system actions identical across platforms. Native integrations and platform-specific permissions will be needed.

## 4. MVP features

1. Email-based registration and login.
2. Authenticated user session.
3. Register and pair a device.
4. Dashboard with device name, platform, online status, and last-seen time.
5. Rename and remove a device.
6. Device agent listens for authorized real-time events through Firebase.
7. Presence/last-seen updates and automatic reconnection.
8. Text-only clipboard synchronization, enabled by user choice.
9. Remote shutdown, restart, and sleep where supported and authorized.
10. Command status and audit history.
11. Device credential revocation.
12. Basic error states for offline devices, permission failures, and timeouts.

## 5. Out of scope for MVP

- Remote desktop, screen streaming, or remote mouse/keyboard control.
- File and folder transfer.
- Arbitrary remote shell or terminal execution.
- BIOS-level power control.
- Guaranteed command execution when the target is offline, sleeping, or powered off.
- Clipboard image, file, or rich-text synchronization.
- Enterprise device administration.
- Guaranteed availability beyond the hosting provider's published service terms.

## 6. Main actors

- **User:** owns an account and manages their devices.
- **Flutter client:** presents device status, settings, and controls.
- **Device agent:** runs on a supported device and performs approved local tasks.
- **Firebase services:** authenticate users, enforce data access rules, deliver real-time events, and store device/command metadata.
- **Device agent:** validates received commands and reports outcomes; privileged pairing transitions use trusted server-side logic where needed.

## 7. Core assumptions

- A device must be powered on and have internet access to receive ordinary commands.
- A sleeping device may not maintain a network connection. Wake-on-LAN is separate and depends on hardware and network configuration.
- An offline command should expire or remain visibly queued according to explicit policy. It must not silently run later after its context is stale.
- Clipboard synchronization is opt-in and must have clear privacy controls.
- Each installation has a separate device identity and revocable credentials.

## 8. Success criteria

The MVP is accepted when a user can:

1. Sign in from two clients.
2. Register a Linux desktop agent and see it in the dashboard.
3. See online/offline changes based on heartbeat and connection state.
4. Connect the phone and desktop over different internet networks.
5. Sync text clipboard content when explicitly enabled.
6. Request a supported system action and receive a truthful status.
7. Revoke the desktop agent so it can no longer receive authorized commands.
8. Verify Firebase transport is encrypted and that Security Rules and trusted pairing logic enforce command authorization.
