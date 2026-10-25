# World of IT: Oracle Deployment Decision

## Decision: Oracle is not part of the initial architecture

World of IT will use Firebase Authentication and Firebase Realtime Database for managed identity and real-time data delivery. Do not provision an Oracle VM for this project. Reserve Oracle compute for other projects.

## Why
- Realtime Database listeners deliver changes without an application server polling continuously.
- Flutter clients and the Linux agent connect outbound to Firebase; home-router port forwarding is not needed.
- A custom FastAPI/WebSocket server would add deployment, TLS, monitoring, patching, and maintenance work without being necessary for the MVP.

## Revisit only if requirements change
Consider a custom server later only if Firebase's quotas, pricing, platform integration, or required protocol make it necessary. Any future backend should be a deliberate decision, not a prerequisite for the current MVP.

Firebase is not unlimited or automatically free at every scale. Check current quotas and billing requirements. Cloud Functions generally require the Blaze plan with billing enabled; they should be limited to trusted operations such as pairing and revocation, not every clipboard event.
