# Frequently Asked Questions (FAQ) - WiFi Sync

### 1. What is WiFi Sync?
WiFi Sync is a high-performance, cross-platform clipboard synchronization and device management application for Android, Linux, and Windows (with iOS, macOS, and Web support). It lets text copied on one device appear instantaneously on your other devices.

---

### 2. Is my clipboard data private? Can the developer see my text?
**No.** WiFi Sync connects exclusively to your personal Firebase Realtime Database. The developer (Muhammad Abu Huraira) has zero servers, zero telemetry endpoints, and zero access to your database. Your clipboard text is encrypted in transit using TLS 1.3 and stored only in your private database.

---

### 3. Why do I connect my own Firebase project?
Connecting your own free Firebase project prevents central server hosting costs and grants you complete data ownership. You maintain full control over your database security rules, users, and stored items.

---

### 4. Will using Firebase cost me any money?
**No.** Firebase provides a generous Spark Free Tier that requires no credit card:
- 1 GB Realtime Database storage
- 10 GB/month data transfer
- 100 simultaneous connections
- 50,000 monthly active authentication users

Personal clipboard synchronization typically uses less than 0.1% of these limits, so it is 100% free indefinitely.

---

### 5. How do I pause syncing when copying sensitive passwords?
You can flip the master **"Clipboard Sync"** switch located at the top of the Dashboard or in Settings. When disabled, the background service immediately stops watching the clipboard.

---

### 6. How does Android background syncing work on Samsung One UI?
Due to Android 10+ background clipboard restrictions:
1. **Accessibility Copy Detector:** Captures copy actions across third-party apps even when WiFi Sync is minimized.
2. **Notification Quick Action:** The persistent notification shade includes a "Send to Laptop" quick action button for foreground-privileged instant synchronization.
3. **Focus Auto-Push:** Whenever WiFi Sync resumes focus, any newly copied text is synchronized immediately.

---

### 7. How do I delete my cloud data or account?
Go to **Settings > Data Management & Privacy Rights**:
- Tap **Clear Cloud Clipboard History** to wipe all remote clipboard entries.
- Tap **Delete Account & Cloud Data** to permanently delete your Firebase user account and all registered device nodes (GDPR Article 17 compliant).

---

### 8. How do I report bugs or suggest features?
Open an issue on GitHub: [github.com/hurairamuzammal/WiFi-Sync/issues](https://github.com/hurairamuzammal/WiFi-Sync/issues) or email Muhammad Abu Huraira at `huraira.eqeel@gmail.com`.
