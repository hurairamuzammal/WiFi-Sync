# World of IT: MVP Roadmap

## Phase 0: Define and prepare
- [ ] Create Git repository and basic Flutter project.
- [ ] Create Firebase project and configure FlutterFire.
- [ ] Define environment variables and secret handling.
- [ ] Skip Oracle provisioning; use Firebase Emulator Suite for local testing.
- [ ] Create issue tracker using the user-story IDs in `USER_STORIES.md`.

**Exit criteria:** project boots locally, environment setup is documented, no secrets are committed.

## Phase 1: Authentication and device dashboard
- [x] Flutter sign-up, login, and logout (Email/Password).
- [ ] Planned Auth Follow-up: Add **Sign Up / Sign In with Google** and **Forgot Password** (`sendPasswordResetEmail`).
- [x] Firebase Authentication manages sessions; Security Rules enforce access.
- [ ] Realtime Database paths for devices and user settings, with tested Security Rules.
- [ ] Register, rename, list, and revoke device.
- [ ] Dashboard loading, empty, and error states.

**Exit criteria:** users see only their own devices and can revoke one.

## Phase 2: Agent connectivity
- [ ] Python Linux agent registers through the trusted pairing flow.
- [ ] Agent listens to authorized Realtime Database paths and reconnects after network loss.
- [ ] Heartbeats update presence.
- [ ] Exponential backoff reconnect.
- [ ] Database presence metadata and stale-timeout logic track last-seen state.

**Exit criteria:** desktop appears online and transitions offline when disconnected; reconnect works.

## Phase 3: Command framework
- [ ] Define strict message schemas.
- [ ] Add command IDs, expiry, state transitions, and audit events.
- [ ] Add per-user and per-device authorization.
- [ ] Add allowlisted test command before power actions.
- [ ] Add rate limits and duplicate rejection.

**Exit criteria:** a harmless test command can be delivered and acknowledged across different networks.

## Phase 4: Clipboard sync
- [ ] Add per-device opt-in setting.
- [ ] Implement Linux text clipboard adapter.
- [ ] Send clipboard events securely.
- [ ] Add origin IDs and duplicate suppression.
- [ ] Add deletion/retention policy.
- [ ] Test offline and reconnect behavior.

**Exit criteria:** text sync works without loops and without logging clipboard payloads.

## Phase 5: Power actions
- [ ] Add confirmation UI.
- [ ] Implement Linux shutdown and restart actions using a narrow allowlist.
- [ ] Handle OS permissions and authorization failures.
- [ ] Handle connection loss before acknowledgement.
- [ ] Add manual tests for pending, success, failure, and unconfirmed states.

**Exit criteria:** supported actions work on the test machine and status reporting never falsely claims success.

## Phase 6: Hardening and release
- [ ] Test revoked credentials.
- [ ] Test expired and replayed commands.
- [ ] Test unauthorized device IDs.
- [ ] Test network interruptions and backend restarts.
- [ ] Review Firebase quotas, billing settings, and export/backup needs.
- [ ] Document install, upgrade, rollback, and recovery.
- [ ] Add Windows support only after the Linux MVP is reliable.

## MVP definition of done

The user can sign in, register a Linux device, see presence, sync text clipboard with opt-in, request a supported power action, receive accurate command status, and revoke the device. Traffic is encrypted and authorization tests pass.
