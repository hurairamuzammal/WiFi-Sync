# World of IT

World of IT is a cross-platform Flutter app for securely pairing a user's devices, syncing text clipboard content in real time, and requesting supported system actions such as shutdown, restart, and sleep over the internet.

## Included documents
- `docs/PROJECT_SCOPE.md`: goals and MVP boundaries.
- `docs/USER_STORIES.md`: epics and acceptance criteria.
- `docs/ARCHITECTURE.md`: Firebase architecture, event flow, and security.
- `docs/TECH_STACK.md`: implementation stack.
- `docs/ROADMAP.md`: staged implementation plan.
- `docs/FIREBASE_SETUP.md`: Firebase setup and usage notes.
- `docs/DATA_MODEL.md`: Realtime Database structure and sample records.

## Technical direction
- Flutter/Dart for the app.
- Firebase Authentication for accounts.
- Firebase Realtime Database for device records, presence metadata, clipboard events, and command queues/listeners.
- Firebase Security Rules to isolate each user's data.
- Firebase Cloud Functions only for operations that must be trusted, such as securely completing pairing or revocation workflows.
- Python Linux desktop agent for the first proof of concept.
- **No Oracle VM, FastAPI server, custom WebSocket server, or webhook service is required for the initial architecture.**

Firebase handles the hosted real-time transport. Devices listen for changes and publish events; they do not poll continuously. Webhooks are not needed for device-to-device clipboard sync.

## First milestone
1. Create a Firebase project and enable Authentication and Realtime Database.
2. Build Flutter sign-in and a minimal device dashboard.
3. Register one Linux desktop agent and enforce per-user database rules.
4. Add trusted-device pairing and revocation.
5. Test real-time messages between two clients on different internet connections.
6. Add text clipboard sync, then allowlisted remote power actions.

## Security baseline
- Deny database access by default; grant only the authenticated owner access to their permitted records.
- A device ID alone is not proof of identity. Pair devices through a short-lived, one-time approval flow.
- Never put Firebase Admin credentials or other server secrets in Flutter or desktop client code.
- Never accept arbitrary shell commands.
- Use event IDs, expiry, duplicate suppression, acknowledgements, and revocation.
- Do not log clipboard contents; sync is opt-in.
