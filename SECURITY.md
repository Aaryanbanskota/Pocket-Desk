# PocketDesk Security Documentation

## 1. Security Philosophy
PocketDesk is built with an offline-first philosophy where the user owns their data. The application does not rely on cloud services, minimizing the attack surface. Data is kept locally on the device and synchronized securely over local networks.

## 2. Authentication Security
- **Password hashing:** We use Argon2id with a time cost of 2, memory cost of 65536 KB, and parallelism of 2.
- **Plaintext passwords:** Passwords are never stored in plaintext under any circumstances.
- **Salt generation:** A cryptographically random 32-byte salt is generated for each user.
- **Brute force protection:** Account lockout mechanism is triggered after N failed attempts.

## 3. Local Data Security
- **Database:** Isar database is used, with the path restricted to the app's sandboxed directory.
- **Secure Storage:** `flutter_secure_storage` is used for storing sensitive keys (leveraging Android Keystore and Linux secret service).
- **Encryption key:** The database encryption key is securely stored in `flutter_secure_storage`.
- **Optional Database Encryption:** Isar database encryption is supported using the securely stored key.

## 4. Pairing Token Security
- **Token fields:**
  - `deviceId` (UUID)
  - `userId`
  - `nonce` (random 32 bytes)
  - `expiration` (5 minutes)
  - `publicKey` (ECDH)
  - `signature` (Ed25519)
- **Token validation:** Includes signature verification, nonce uniqueness check, and expiration check.
- **Replay attack prevention:** A nonce registry with TTL prevents replay attacks.
- **QR Code:** Displayed for pairing purposes for a maximum of 5 minutes.

## 5. Transport Security
- **Encryption:** Encrypted WebSocket connection using AES-256-GCM.
- **Nonce:** Per-message nonce (96-bit random).
- **Key Exchange:** ECDH key exchange at pairing using X25519.
- **Message Authentication:** HMAC-SHA256 for message integrity.
- **Forward Secrecy:** Supported through ephemeral key exchanges where applicable.

## 6. Input Validation
- All user inputs are rigorously sanitized and validated.
- Filenames are validated before any attachment is stored.
- ICS import mechanisms use safe parsing techniques to prevent code execution.

## 7. Platform-Specific Security
- **Android:** Utilizes the hardware-backed Android Keystore.
- **Ubuntu:** Utilizes the Linux Secret Service (libsecret).
- **App Sandboxing:** Relies on OS-level app sandboxing to isolate data.

## 8. Threat Model
- **In-scope threats:** Local data theft, network interception (MITM), replay attacks, malicious QR codes.
- **Out-of-scope threats:** Physical device compromise, OS-level malware/rootkits.

## 9. Security Checklist
For each release, ensure:
- Dependencies are audited for known vulnerabilities.
- Cryptographic parameters are reviewed against current standards.
- Token validation and session management logic are tested.
- Platform security configurations (Keystore, libsecret) are functioning properly.
- No sensitive keys or passwords are inadvertently logged.

## 10. Vulnerability Reporting
Please report any security vulnerabilities privately. Do not open public issues for security exploits.
