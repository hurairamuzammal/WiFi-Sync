# 100% Free Firebase Setup Guide (3 Minutes)

WiFi Sync operates on a bring-your-own-cloud model. You can set up your own free Firebase project in about 3 minutes without entering any credit card information.

---

### Step 1: Create a Free Firebase Project
1. Open the [Firebase Console](https://console.firebase.google.com).
2. Click **Add project** (or **Create a project**).
3. Name your project (e.g., `my-wifisync-hub`).
4. (Optional) Disable Google Analytics if you prefer maximum privacy.
5. Click **Create project** and wait 15 seconds.

---

### Step 2: Enable Authentication
1. In the left navigation bar, go to **Build > Authentication**.
2. Click **Get Started**.
3. Under the **Sign-in method** tab, click **Email/Password** and toggle **Enable**.
4. (Optional) If you want one-tap Google Sign-In, also toggle **Google** and select your support email.
5. Click **Save**.

---

### Step 3: Create Realtime Database
1. In the left navigation bar, go to **Build > Realtime Database**.
2. Click **Create Database**.
3. Choose your nearest database location (e.g., `United States (us-central1)`).
4. For security rules, select **Start in test mode** (or import the hardened `database.rules.json` file provided in the repository root).
5. Click **Enable**.
6. Copy your Database URL (looks like `https://my-wifisync-hub-default-rtdb.firebaseio.com`).

---

### Step 4: Get Your Project ID and Web API Key
1. Click the **Gear icon (Project settings)** in the top-left sidebar.
2. Under the **General** tab:
   - Find your **Project ID** (e.g. `my-wifisync-hub-12345`).
   - Find your **Web API Key** (starts with `AIzaSy...`).

---

### Step 5: Connect in WiFi Sync
Open the WiFi Sync application on any device:
1. On the Sign-In screen, tap **Connect** on the top cloud strip (or go to **Settings > Cloud Backend > Configure**).
2. Enter your:
   - **Firebase Project ID**
   - **Web / REST API Key**
   - **Database URL** (optional, auto-derived if omitted)
3. Tap **Test Connection** to confirm connectivity.
4. Tap **Save & Apply**.

You are now syncing clipboards across your devices on your own private cloud at $0 cost!
