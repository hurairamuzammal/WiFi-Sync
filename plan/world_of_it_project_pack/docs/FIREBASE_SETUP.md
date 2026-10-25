# Firebase Setup for World of IT

## Create the project
1. Create a Firebase project in the Firebase Console. No Oracle VM is needed.
2. Register the Flutter app(s) with Firebase using FlutterFire CLI and configure `firebase_core` plus `firebase_auth` and `firebase_database`.
3. Enable the sign-in provider you want (email/password is a simple starting point).
4. Create a Realtime Database in a suitable region.
5. Start with deny-by-default Security Rules; do not use open test-mode rules for a real account.
6. Use Firebase Emulator Suite for local rule and workflow testing.

## Suggested Realtime Database layout

```json
{
  "users": {
    "UID": {
      "profile": { "createdAt": 1790000000000 },
      "devices": {
        "DEVICE_ID": {
          "displayName": "ThinkPad",
          "platform": "linux",
          "trusted": true,
          "revoked": false,
          "clipboardSyncEnabled": true,
          "lastSeenAt": 1790000000000
        }
      },
      "clipboardEvents": {
        "EVENT_ID": {
          "sourceDeviceId": "DEVICE_ID",
          "text": "example",
          "createdAt": 1790000000000,
          "expiresAt": 1790000060000
        }
      },
      "commands": {
        "COMMAND_ID": {
          "targetDeviceId": "DEVICE_ID",
          "action": "health_check",
          "status": "pending",
          "createdAt": 1790000000000,
          "expiresAt": 1790000060000
        }
      },
      "pairingRequests": {
        "PAIRING_ID": {
          "newDeviceName": "Android phone",
          "status": "pending",
          "expiresAt": 1790000060000
        }
      }
    }
  }
}
```

This is a conceptual layout, not ready-to-deploy Security Rules. Do not copy the sample timestamps or use permissive rules. Design rules around the exact operations each client is allowed to perform. Clients must not be able to set `trusted: true`, change ownership, or forge command results themselves. Use a trusted Cloud Function for protected transitions when rules alone cannot safely enforce them.

## Real-time event design
- Use listeners on the narrowest paths possible, not the entire database.
- Clipboard event: unique ID, source device ID, text, creation time, expiry. Delete quickly; do not create permanent history by default.
- Command: unique ID, target device ID, allowlisted action, creator device ID, status, creation time, expiry, acknowledgement/result fields.
- Ignore duplicate event IDs and remote-origin clipboard updates to prevent loops.
- Avoid rapid heartbeat writes; use a modest interval and stale-timeout logic.

## Billing and quotas
- Check current Firebase plan limits before testing with many devices. Realtime listeners consume connections and downloads.
- Cloud Functions deployment generally requires the Blaze plan with a linked billing account. If you need pairing functions, enable billing only after reviewing pricing and setting budget alerts.
- No Oracle compute is required by this plan.
