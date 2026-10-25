# World of IT: Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Client UI | Flutter and Dart | Cross-platform app |
| Authentication | Firebase Authentication | Managed account login/session |
| Real-time data and events | Firebase Realtime Database | Live listeners, clipboard events, commands, device metadata |
| Authorization | Firebase Security Rules | Per-user and per-device data isolation |
| Trusted server-side operations | Firebase Cloud Functions, when needed | Pairing approval, revocation, privileged state transitions |
| Initial desktop agent | Python on Linux | Clipboard adapter, command listener, power actions |
| Source control | Git and GitHub | Version control |

## Keep the first version simple
- Do not deploy Oracle compute.
- Do not build a custom FastAPI/WebSocket server.
- Do not add webhooks for normal clipboard delivery; Realtime Database listeners already deliver changes.
- Use Cloud Functions only where a client must not be trusted to perform the operation. Build and test with the Firebase Emulator Suite where practical.
- Keep the first working end-to-end flow to two running clients and text clipboard sync.

## Important cost note
Firebase Authentication and Realtime Database have no-cost allowances, subject to current plan quotas. Deploying Cloud Functions generally requires the Blaze pay-as-you-go plan and billing enabled, even when usage may fit within free allowances. Avoid deploying Functions until the pairing workflow needs them, and review current Firebase pricing and limits before enabling billing.

## Platform notes
- Begin with Linux desktop agent support, then add Windows/macOS after the flow is reliable.
- Flutter mobile clipboard behavior is limited by OS background restrictions; do not promise universal background clipboard monitoring.
- Never ship Firebase Admin credentials in a client. Use Security Rules and trusted server-side code for privileged actions.
