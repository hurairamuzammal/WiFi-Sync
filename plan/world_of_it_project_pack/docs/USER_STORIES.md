# World of IT: User Stories and Acceptance Criteria

Priorities: **P0** = required for MVP, **P1** = important, **P2** = later enhancement.

## Epic A: Account and authentication

### US-01: Create an account
**Priority:** P0  
As a user, I want to create an account so I can manage my devices.

Acceptance criteria:
- A valid registration creates an account through the configured authentication provider.
- Invalid input and authentication errors are shown clearly.
- Secrets and passwords are never written to application logs.

### US-02: Sign in
**Priority:** P0  
As a user, I want to sign in from a supported device.

Acceptance criteria:
- Successful sign-in opens the device dashboard.
- Failed sign-in does not expose whether unrelated users exist.
- The session is stored using platform-appropriate secure storage where required.

### US-03: Sign out
**Priority:** P0  
As a user, I want to sign out securely.

Acceptance criteria:
- The local session is cleared.
- Protected screens and API requests require authentication.
- The user can sign in again.

## Epic B: Device management

### US-04: Register a device
**Priority:** P0  
As a user, I want to register a device to my account.

Acceptance criteria:
- The trusted pairing flow assigns or verifies a unique device identity.
- The device is associated with the authenticated account.
- A device-specific credential is issued securely.
- Registration cannot attach a device to another user's account without authorized pairing.

### US-05: View all devices
**Priority:** P0  
As a user, I want to see my devices in one dashboard.

Acceptance criteria:
- The dashboard shows device name, platform, online/offline state, and last-seen time.
- Only devices owned by the signed-in user are returned.
- Loading, empty, and error states are supported.

### US-06: Rename a device
**Priority:** P1  
As a user, I want to rename a device so I can identify it easily.

Acceptance criteria:
- The new name is validated and saved.
- The new name appears on the user's other clients after refresh or live update.

### US-07: Remove a device
**Priority:** P0  
As a user, I want to remove a device I no longer trust.

Acceptance criteria:
- The user must confirm removal.
- The device's credential is revoked.
- New commands are rejected for the revoked device.
- The dashboard updates to reflect removal.

### US-08: Pair a new device
**Priority:** P1  
As a user, I want to approve a new device securely.

Acceptance criteria:
- Pairing requires an authenticated flow, one-time code, or approval from a trusted device.
- Pairing tokens expire and cannot be reused.
- The user can cancel pairing.

## Epic C: Presence and connectivity

### US-09: Show device presence
**Priority:** P0  
As a user, I want to know whether a device is reachable.

Acceptance criteria:
- Agents send periodic heartbeats or maintain a live authenticated connection.
- The server marks a device offline after a configurable timeout.
- The UI does not claim that an offline device is reachable.

### US-10: Reconnect automatically
**Priority:** P0  
As a user, I want my device to reconnect after an internet interruption.

Acceptance criteria:
- The agent retries with backoff.
- Reconnection refreshes presence.
- Reconnection does not create duplicate device records.

### US-11: Connect across networks
**Priority:** P0  
As a user, I want my devices to communicate when they are on different networks.

Acceptance criteria:
- Agents initiate outbound connections to the backend.
- No inbound port forwarding on the user's home router is required for the normal connection flow.
- TLS and device authentication are required.

## Epic D: Clipboard synchronization

### US-12: Sync text clipboard
**Priority:** P0  
As a user, I want copied text to be available on my other authorized devices.

Acceptance criteria:
- Sync is disabled by default until the user enables it.
- Text is transmitted over TLS only to authorized account devices.
- The sender, target, and timestamp are associated with each sync event.
- Platform restrictions are handled with a clear status message.

### US-13: Disable clipboard sync
**Priority:** P0  
As a user, I want to disable clipboard sync for privacy.

Acceptance criteria:
- Disabling sync stops new clipboard uploads from that device.
- The setting persists across app restarts.
- Existing server-side clipboard data follows the configured retention and deletion policy.

### US-14: Avoid sync loops
**Priority:** P0  
As a user, I want incoming clipboard text not to bounce endlessly between devices.

Acceptance criteria:
- Sync events have unique IDs and origin metadata.
- Agents recognize content received through synchronization.
- Duplicate events are ignored.

### US-15: Clear clipboard data
**Priority:** P1  
As a user, I want to clear any stored clipboard history.

Acceptance criteria:
- If clipboard history exists, the user can clear it.
- Retention duration is documented and configurable.
- Sensitive clipboard data is not retained indefinitely.

## Epic E: Remote system actions

### US-16: Shut down a device
**Priority:** P0  
As a user, I want to shut down my supported computer remotely.

Acceptance criteria:
- The user selects a specific device and confirms shutdown.
- Firebase authorization rules and trusted command-state logic check ownership, permissions, device status, and command expiry.
- The agent accepts only explicitly supported actions.
- The app shows the last known command status and does not falsely claim success if no acknowledgement arrives.

### US-17: Restart a device
**Priority:** P0  
As a user, I want to restart my supported computer remotely.

Acceptance criteria:
- Restart requires confirmation.
- The agent uses a platform-specific, permitted implementation.
- The app shows accepted, execution-requested, and confirmed/unconfirmed status accurately.

### US-18: Put a device to sleep
**Priority:** P1  
As a user, I want to put my supported computer to sleep remotely.

Acceptance criteria:
- The feature is enabled only on supported platforms.
- Permission or policy errors are reported.
- The UI explains that a sleeping device may disconnect and may not be able to receive further commands.

### US-19: View command result
**Priority:** P0  
As a user, I want to know what happened to a remote action.

Acceptance criteria:
- Each command has a unique ID.
- States include pending, delivered/accepted, succeeded where verifiable, failed, expired, and unconfirmed.
- A missing acknowledgement is not represented as success.

### US-20: Cancel a pending command
**Priority:** P2  
As a user, I want to cancel a command that has not executed.

Acceptance criteria:
- Cancellation is allowed only before execution begins.
- The database state and agent coordinate command state.
- The UI explains when cancellation is too late.

## Epic F: Security and audit

### US-21: Protect command delivery
**Priority:** P0  
As a user, I want only my authorized devices to receive my commands.

Acceptance criteria:
- Firebase Security Rules and trusted command-state logic verify account ownership for every target device.
- Device credentials are unique, revocable, and never shared across devices.
- Client-supplied device IDs are not treated as proof of ownership.

### US-22: Encrypt traffic
**Priority:** P0  
As a user, I want device and server communication protected in transit.

Acceptance criteria:
- Firebase client connections use TLS.
- Production configuration rejects insecure connections.
- Secrets are supplied through environment configuration, not committed to source control.

### US-23: Review command history
**Priority:** P1  
As a user, I want to review recent remote actions.

Acceptance criteria:
- Logs contain command ID, target device, action, timestamps, and result.
- Logs do not contain passwords, access tokens, or clipboard text.
- Users can view only their own records.

### US-24: Prevent arbitrary command execution
**Priority:** P0  
As a user, I want the remote-control feature to be limited to safe, defined operations.

Acceptance criteria:
- The API accepts an allowlist of actions, not arbitrary shell strings.
- The agent validates every action.
- Commands have expiry times and replay protection.
- Destructive actions require explicit user confirmation.

## Epic G: Reliability and settings

### US-25: Handle offline devices
**Priority:** P0  
As a user, I want to know when a device cannot receive a command.

Acceptance criteria:
- The app warns when a target is offline.
- Expired commands are not executed later without a fresh request.
- The UI distinguishes failed delivery from failed execution.

### US-26: Configure clipboard and notifications
**Priority:** P1  
As a user, I want to control synchronization and notifications.

Acceptance criteria:
- Clipboard sync can be enabled or disabled per device.
- Notification preferences persist.
- The user can identify which settings apply to each device.

## MVP completion checklist

- [ ] Authentication works.
- [ ] Device registration and revocation work.
- [ ] Dashboard shows presence and last seen.
- [ ] Linux agent reconnects after network loss.
- [ ] Devices communicate across separate networks.
- [ ] Text clipboard sync works with explicit opt-in.
- [ ] Shutdown and restart work on the supported Linux test machine.
- [ ] Command state is accurate and auditable.
- [ ] Ownership checks and device revocation are tested.
- [ ] Production endpoints use TLS.
