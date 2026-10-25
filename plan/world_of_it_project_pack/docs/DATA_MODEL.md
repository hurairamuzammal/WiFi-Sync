# World of IT: Firebase Realtime Database Model

This is a conceptual Realtime Database structure, not a production-ready rules file. Firebase Realtime Database is a JSON tree rather than a relational database; keep paths shallow and subscribe only to the records a client needs.

## Suggested layout

```text
users/{uid}/profile
users/{uid}/devices/{deviceId}
users/{uid}/pairingRequests/{pairingId}
users/{uid}/clipboardEvents/{eventId}
users/{uid}/commands/{commandId}
users/{uid}/auditEvents/{eventId}
```

## `profile`
- `createdAt`: server timestamp.
- Do not store passwords; Firebase Authentication owns account credentials.

## `devices/{deviceId}`
- `displayName`: short user-visible name.
- `platform`: allowlisted value (`linux`, `windows`, `macos`, `android`, `ios`).
- `agentVersion`: optional string.
- `trusted`: boolean set only by trusted pairing flow.
- `revoked`: boolean/state set only by authorized revocation flow.
- `clipboardSyncEnabled`: boolean, default false.
- `lastSeenAt`: timestamp.
- `createdAt`: timestamp.

A device ID is an identifier, not a secret or proof of authorization. Do not store raw long-lived secrets in readable database paths. Use platform secure storage for local credentials and trusted server-side logic for issuing/revoking them.

## `pairingRequests/{pairingId}`
- `newDeviceName`, `newDevicePlatform`.
- `status`: `pending`, `approved`, `rejected`, `expired`, or `cancelled`.
- `createdAt`, `expiresAt`.
- `approvedByDeviceId`: set only by the trusted approval flow.

Pairing codes must be one-time, short-lived, and unguessable. Do not allow clients to approve their own pairing request or directly set a new device to trusted.

## `clipboardEvents/{eventId}`
- `sourceDeviceId`.
- `text`: clipboard text, only while needed for delivery.
- `createdAt`, `expiresAt`.
- Optional `contentHash` for duplicate suppression; avoid retaining raw text in logs.

Prefer transient events and quick deletion rather than clipboard history. Ensure only trusted devices with sync enabled can read relevant events.

## `commands/{commandId}`
- `targetDeviceId`.
- `requestedByDeviceId`.
- `action`: allowlisted value such as `shutdown`, `restart`, `sleep`, `health_check`.
- `status`: `pending`, `accepted`, `succeeded`, `failed`, `expired`, `cancelled`, or `unconfirmed`.
- `createdAt`, `expiresAt`, `acceptedAt`, `finishedAt`.
- `resultCode`: safe, sanitized machine-readable result.

Clients must not be able to forge successful command results or target another user's device. Expired commands must not execute on reconnection.

## `auditEvents/{eventId}`
- `eventType`, `deviceId`, `commandId`, `createdAt`.
- Minimal sanitized metadata only. Never include tokens, passwords, or clipboard text.

## Security rules requirements
- Default deny.
- Authenticate all reads/writes that are not intentionally public.
- Scope every path to the authenticated user's UID and validate the device's trusted/non-revoked status.
- Limit fields, types, text sizes, allowed actions, and legal state transitions.
- Do not let clients change ownership, mark devices trusted, revoke other devices without authorization, or forge results.
- Test rules in the Firebase Emulator Suite before real use.
