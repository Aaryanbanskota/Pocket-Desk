# PocketDesk WebSocket Protocol

## 1. Connection Establishment
WebSocket connections are initiated by the secondary device to the primary device at `ws://<device-ip>:4040/ws`. The connection upgrades from HTTP to WebSocket using standard protocols.

## 2. Authentication Handshake
Immediately after connection, the secondary device must send a `HELLO` message containing its device token. The server will respond with `HELLO_ACK` if authentication is successful. If no `HELLO` is received within 5 seconds, or if auth fails, the server closes the connection.

## 3. Message Envelope Format
All messages exchanged over the WebSocket must adhere to this JSON structure:
```json
{
  "type": "MESSAGE_TYPE",
  "messageId": "uuid",
  "timestamp": 1690000000,
  "deviceId": "uuid",
  "signature": "hmac-sha256-signature",
  "payload": {}
}
```

## 4. Message Type Reference

- **`HELLO`**: Initiates the authentication handshake.
- **`HELLO_ACK`**: Confirms successful authentication.
- **`SYNC_PUSH`**: Pushes local changes to the remote device.
- **`SYNC_ACK`**: Acknowledges successful receipt and processing of a `SYNC_PUSH`.
- **`SYNC_NACK`**: Rejects a `SYNC_PUSH` (e.g., due to format errors or severe conflicts).
- **`SYNC_PULL_REQUEST`**: Requests updates since a specific vector clock.
- **`SYNC_PULL_RESPONSE`**: Returns the requested updates.
- **`HEARTBEAT`**: Ping message to keep the connection alive.
- **`HEARTBEAT_ACK`**: Pong response to a heartbeat.
- **`DISCONNECT`**: Graceful termination of the connection.
- **`ERROR`**: Indicates a protocol or server error.

## 5. Payload Schemas

**`HELLO` Payload:**
```json
{
  "token": "device-pairing-token",
  "clientVersion": "1.0.0"
}
```

**`SYNC_PUSH` Payload:**
```json
{
  "deltas": [
    {
      "entityId": "uuid",
      "entityType": "task",
      "changes": {"title": "Buy Milk"},
      "vectorClock": {"device1": 10}
    }
  ]
}
```

## 6. State Machine Diagram

```
[DISCONNECTED] --(connect)--> [CONNECTING] --(upgrade)--> [AUTHENTICATING]
[AUTHENTICATING] --(send HELLO)--> [WAIT_HELLO_ACK]
[WAIT_HELLO_ACK] --(receive HELLO_ACK)--> [CONNECTED]
[WAIT_HELLO_ACK] --(timeout/fail)--> [DISCONNECTED]
[CONNECTED] --(SYNC/HEARTBEAT)--> [CONNECTED]
[CONNECTED] --(error/disconnect)--> [DISCONNECTED]
```

## 7. Error Handling and Retry Semantics
- Messages that require an acknowledgment (`HELLO`, `SYNC_PUSH`) include a `messageId`.
- If an ACK is not received within a timeout window (e.g., 5 seconds), the sender will retry up to 3 times.
- If all retries fail, the connection is considered unstable, and the client will disconnect and initiate the reconnect backoff strategy.
- `ERROR` messages include an error code and a human-readable message for logging.

## 8. Connection Lifecycle
1. **Connect**: TCP and WebSocket upgrade.
2. **Authenticate**: `HELLO` exchange.
3. **Active**: Standard message flow (`SYNC`, `HEARTBEAT`).
4. **Terminate**: Can be initiated gracefully via `DISCONNECT` or abruptly via network failure. Terminations trigger the offline queueing system.
