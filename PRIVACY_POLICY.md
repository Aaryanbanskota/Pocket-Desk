# PocketDesk Privacy Policy

**Last Updated: September 27, 2026**

Your privacy is our top priority. PocketDesk is designed from the ground up as an **offline-first, privacy-respecting productivity application**.

---

### 1. Information Collection & Usage
- **Zero Telemetry**: We do not collect, track, or sell your personal data, usage analytics, or identity metrics.
- **Local Credentials**: Passwords and security recovery answers are hashed locally using **Argon2id** (with unique salts per account). Plaintext passwords are never saved anywhere on disk.

---

### 2. Network Communication
- **Update Checks**: PocketDesk checks `https://raw.githubusercontent.com/Aaryanbanskota/Pocket-Desk/main/update.json` for new app versions. No personal identification data is sent during update checks.
- **P2P Sync**: Synchronization between devices occurs across your local network with end-to-end AES-GCM-128 encryption.

---

### 3. AI & External Services
- AI assistance functions only when you configure an API key.
- Prompts sent to AI providers (e.g. OpenRouter) travel directly from your device to the API provider. PocketDesk acts strictly as a client and never intercepts or proxies your AI conversations.

---

### 4. Account Deletion & Data Wipe
- You have the absolute right to purge all data at any time.
- Navigating to **Settings → Privacy → Delete Account** triggers a 2-step total wipe of all Isar database tables, encryption keys, and secure storage items.

---

### 5. Policy Updates & Inquiries
This policy may be updated alongside new releases. You can view updates at:  
[PocketDesk Privacy Policy](https://github.com/Aaryanbanskota/Pocket-Desk/blob/main/PRIVACY_POLICY.md)
