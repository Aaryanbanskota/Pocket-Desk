# PocketDesk Sync Protocol

## 1. Overview
The PocketDesk synchronization protocol operates on a peer-to-peer model with no central server. The user's primary device runs the backend, and secondary devices connect to it. Syncing happens directly over the local network or via securely tunneled connections.

## 2. Device Pairing Flow

1. **Step 1:** Primary device generates a signed QR token containing connection info and public keys.
2. **Step 2:** Secondary device scans the QR code.
3. **Step 3:** Secondary device validates the token (signature, nonce, expiration).
4. **Step 4:** Key exchange occurs (Diffie-Hellman or ECDH) to establish shared secrets.
5. **Step 5:** Secondary device sends a pairing confirmation payload back to the primary device.
6. **Step 6:** An encrypted communication channel is established for all future requests.

## 3. Sync Architecture

- **Vector Clocks:** Used to track causality and detect concurrent modifications across distributed devices.
- **Delta Sync:** Only modified fields (deltas) of changed entities are transmitted over the network, minimizing payload sizes.
- **Entity Types:** Support for `calendar_events`, `tasks`, `notes`, `settings`.
- **Change Tracking:** Entities use `updatedAt` timestamps and `isDeleted` flags for soft-deletes.

## 4. Sync Flow

- **Initial Full Sync:** Triggered immediately after a new device is paired to download the entire state.
- **Incremental Delta Sync:** Occurs periodically or immediately upon local changes.
- **Offline Queue Drain:** When a device reconnects after being offline, it drains its local queue of pending changes before pulling new updates.
- **Conflict Detection:** Managed by comparing vector clocks and timestamps.

## 5. Conflict Resolution

- **Last-Write-Wins (LWW):** Conflicts are automatically resolved based on the most recent `updatedAt` timestamp.
- **User-Facing Conflict UI:** For complex conflicts (future implementation), users will be prompted to manually resolve them.
- **Merge Strategy:** Structured fields (like arrays or deeply nested JSON) use intelligent merge strategies to combine changes when possible.

## 6. Security

- **ECDH Key Exchange:** Secure key agreement during the pairing phase.
- **AES-256-GCM:** Used for encrypting WebSocket messages and sensitive REST payloads.
- **Per-Message Nonce:** Ensures each message is uniquely encrypted.
- **Replay Attack Prevention:** A nonce registry and short expiration times prevent captured messages from being reused.

## 7. Reconnect & Heartbeat

- **Heartbeat Interval:** Devices ping each other every 30 seconds to ensure the connection is alive.
- **Exponential Backoff:** Disconnected devices attempt to reconnect using exponential backoff (1s, 2s, 4s, 8s... max 60s).
- **Offline Queue:** Changes made while offline are persisted in an Isar `SyncQueue` collection and synced upon reconnection.

## 8. Message Format Specifications (JSON Schemas)

**Delta Payload Example:**
```json
{
  "entityId": "uuid-1234",
  "entityType": "note",
  "changes": {
    "title": "New Title",
    "updatedAt": 1690000000
  },
  "vectorClock": {
    "deviceA": 5,
    "deviceB": 2
  }
}
```
