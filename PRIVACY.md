# Privacy Policy for WiFi Sync

**Effective Date:** October 26, 2026  
**Last Updated:** October 26, 2026  
**Developer & Maintainer:** Muhammad Abu Huraira (`huraira.eqeel@gmail.com`)  
**Jurisdiction Compliance:** European Union GDPR (General Data Protection Regulation), California Consumer Privacy Act (CCPA / CPRA), CalOPPA, and global data privacy standards.

---

## 1. Core Principle: Bring Your Own Cloud & Zero Intermediaries

WiFi Sync is built on an absolute **self-hosted, user-owned architecture**.
- WiFi Sync connects directly and exclusively to the user's personal Firebase Realtime Database or private server.
- The developer (Muhammad Abu Huraira) and any third-party providers have **zero access, zero visibility, and zero interception capabilities** over your database, your authentication tokens, or your clipboard contents.
- There are no intermediary proxy servers, telemetry collectors, or central databases.

---

## 2. Information We Process

### A. Ephemeral Clipboard Data
- **What is collected:** Plain text copied by the user on authorized devices when "Clipboard Sync" is enabled.
- **Purpose:** Transmitting text exclusively to the user's other authenticated devices via their own Firebase RTDB instance.
- **Storage:** Synced items in Firebase are ephemeral and can be deleted at any time by the user.

### B. Device Presence & Heartbeats
- **What is collected:** Random device UUID, user-assigned device display name (e.g. "Laptop ThinkPad", "Samsung Galaxy A34"), operating system platform name (`android`, `linux`, `windows`), and a periodic timestamp heartbeat.
- **Purpose:** Displaying online/offline status and device connectivity on your personal dashboard.

### C. Authentication Credentials
- **What is collected:** User email and password hash.
- **Purpose:** Authenticating access to your private Firebase database.
- **Handling:** Authentication is managed directly by Google Firebase Authentication. Password hashes are never accessible to WiFi Sync or its developers.

---

## 3. Zero Third-Party Tracking & Zero Monetization

WiFi Sync does **NOT**:
- Include advertising SDKs or banner ads.
- Include analytics trackers (e.g., Google Analytics, Facebook Pixel, Mixpanel, AppsFlyer).
- Track device locations, GPS coordinates, or IP geolocation.
- Sell, lease, rent, or trade user data to third parties, brokers, or affiliates.

---

## 4. Encryption & Security Standards

- **TLS 1.3 Transport Security:** All network communications between WiFi Sync and Firebase are strictly encrypted using HTTPS / WSS with TLS 1.3.
- **Local Credentials:** Auth tokens and session identifiers are stored using platform-native secure storage or sandboxed application preferences.
- **Restricted Access:** Firebase security rules (`database.rules.json`) ensure only authenticated sessions matching the owner's UID can read or write data.

---

## 5. User Rights Under GDPR & CCPA

Under the European Union GDPR (Articles 15 through 22) and California CCPA / CPRA, you have the following guaranteed rights:

1. **Right to Access & Portability (GDPR Art. 15):** You have real-time visibility into all paired devices and synchronized events directly in the application.
2. **Right to Erasure / "Right to be Forgotten" (GDPR Art. 17):**
   - **Clear Cloud Clipboard:** Settings > Data Management > "Clear Cloud Clipboard History" immediately deletes all synchronized entries from Firebase.
   - **Delete Account & All Data:** Settings > Data Management > "Delete Account & Cloud Data" immediately destroys your authentication account, device registration nodes, and cloud storage.
3. **Right to Opt-Out (CCPA):** You can suspend clipboard monitoring instantly by toggling the master "Clipboard Sync" switch.

---

## 6. Children's Online Privacy Protection (COPPA)

WiFi Sync is intended for general developer and productivity use and does not knowingly collect or solicit personal information from children under the age of 13.

---

## 7. Contact Data Protection Officer

For privacy questions, compliance verification, or inquiries:

- **Data Protection Officer / Lead Developer:** Muhammad Abu Huraira
- **Email:** `huraira.eqeel@gmail.com`
- **Location:** Lahore, Punjab, Pakistan
- **Repository Issues:** [github.com/hurairamuzammal/WiFi-Sync/issues](https://github.com/hurairamuzammal/WiFi-Sync/issues)
