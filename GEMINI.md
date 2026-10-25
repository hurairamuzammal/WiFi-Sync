# Repository Rules (`world_of_iot`)

- **Repository-Scoped File Access**: You are allowed to read, create, and edit any file within `/home/user/Extras/Flutter-Projects-Backup/working/world_of_iot` without asking for permission, EXCEPT for `.env` / `.evns` files where you must always ask for permission first.
- **No Outside Repo Modifications**: Do NOT read or modify project files outside `/home/user/Extras/Flutter-Projects-Backup/working/world_of_iot` unless explicitly requested by the user.
- **Web Search Allowed**: You may search any website (`search_web`) freely when working in this repository.
- **Git Push Restriction**: NEVER run `git push` or push changes to any remote repository without the user specifically and explicitly commanding you to push.
- **No LaTeX / MathJax**: NEVER use LaTeX or MathJax formatting (`$$`, `$`, `\frac`, `\mathcal`, `\sum`, etc.). Always use plain text or markdown code blocks.

## Project Memory & Planned Backlog (`world_of_iot`)
- **Live Firebase Project**: `world-of-iot-hub` (`https://world-of-iot-hub-default-rtdb.firebaseio.com`, account `huraira.eqeel@gmail.com`).
- **Completed V2 Enhancements**:
  - [x] **Google Sign-In / Sign-Up**: Added OAuth Google authentication (`signInWithProvider(GoogleAuthProvider())`) alongside Email/Password in Firebase Auth and the Flutter `AuthScreen`, with Android SHA-1/SHA-256 registered on `world-of-iot-hub`.
  - [x] **Forgot Password (Email Accounts Only)**: Added password reset email flow (`sendPasswordResetEmail`) in `AuthScreen` and `SettingsScreen`, strictly restricted to Email & Password accounts (blocked for Google OAuth accounts).
  - [x] **Developer & Version Page (`v2.1.0`)**: Added `DeveloperScreen` featuring **Muhammad Abu Huraira** (`huraira.eqeel@gmail.com`) and colorful purplish brand/launcher icons.
  - [x] **Seamless V2 Auto-Sync & Linux Top Bar**: Added 1s auto-clipboard sync, Samsung floating pill toast + alert sound, unread top-right badge, Linux top bar indicator (`pystray`), and systemd autostart (`world-of-iot-agent.service`).

