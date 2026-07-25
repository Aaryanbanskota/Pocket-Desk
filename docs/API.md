# PocketDesk API Documentation

## 1. Overview
The PocketDesk backend server is built using Dart and Shelf. It is designed to run locally on the user's primary device, facilitating synchronization and pairing with secondary devices. There are no centralized user accounts; instead, devices authenticate directly with the primary device. The API utilizes REST for pairing and initial data exchange, and WebSockets for real-time synchronization.

## 2. Base URL Conventions
All REST API endpoints are prefixed with the base URL:
`http://<device-ip>:4040/api/v1`

## 3. Authentication
Authentication is required for most endpoints, achieved via a device pairing token.
Include the token in the headers of your requests:
`Authorization: Bearer <device-pairing-token>`

## 4. Pairing REST API

### `GET /api/v1/health`
Checks the health and reachability of the primary device server.
- **Auth required**: No
- **Response**: `200 OK`

### `POST /api/v1/pair/init`
Generates a QR token for a new device to scan.
- **Auth required**: No (Requires physical access to the primary device UI)
- **Response**: 
  ```json
  {
    "deviceId": "string",
    "userId": "string",
    "nonce": "string",
    "expiration": "number",
    "publicKey": "string",
    "signature": "string"
  }
  ```

### `POST /api/v1/pair/complete`
Secondary device sends the signed token back to confirm the pairing process.
- **Auth required**: No (Uses payload signature)
- **Request Body**: (The scanned QR token)
- **Response**: `200 OK` (Returns session credentials)

### `GET /api/v1/devices`
Lists all paired devices.
- **Auth required**: Yes
- **Response**: Array of paired device objects.

### `DELETE /api/v1/devices/:deviceId`
Unpairs and removes a specific device.
- **Auth required**: Yes
- **Response**: `204 No Content`

## 5. Sync REST API

### `GET /api/v1/sync/state`
Retrieves the current vector clock / sync state from the primary device.
- **Auth required**: Yes
- **Response**: Current vector clock map.

### `POST /api/v1/sync/pull`
Pulls changes that have occurred since a specified timestamp or vector clock.
- **Auth required**: Yes
- **Request Body**: `{"since": "vector_clock_or_timestamp"}`
- **Response**: Array of delta changes.

### `POST /api/v1/sync/push`
Pushes a batch of local changes to the primary device.
- **Auth required**: Yes
- **Request Body**: Array of delta changes.
- **Response**: `200 OK`

## 6. WebSocket API
WebSocket connections are established at:
`ws://<device-ip>:4040/ws`

### Message Types
- `HELLO`
- `SYNC_PUSH`
- `SYNC_ACK`
- `HEARTBEAT`
- `HEARTBEAT_ACK`
- `DISCONNECT`
- `ERROR`

### Message Format (JSON)
```json
{
  "type": "string",
  "messageId": "string",
  "timestamp": "number",
  "payload": {}
}
```

## 7. Error Codes and Responses
- `400 Bad Request`: Malformed request or missing parameters.
- `401 Unauthorized`: Missing or invalid pairing token.
- `403 Forbidden`: Device is paired but lacks permissions for the action.
- `404 Not Found`: The requested resource does not exist.
- `409 Conflict`: Sync conflict detected (usually handled at the sync protocol layer).
- `500 Internal Server Error`: An unexpected server error occurred.

## 8. Rate Limiting and Security Notes
- **Rate Limiting**: The server enforces reasonable rate limits (e.g., 100 requests per minute per device) to prevent abuse and ensure stability.
- **Security**: The API is meant to be accessed over a local network. For sensitive data exchange, payloads are encrypted end-to-end between devices using keys established during the pairing phase. Replay attacks are mitigated using nonces in the authentication flows.
