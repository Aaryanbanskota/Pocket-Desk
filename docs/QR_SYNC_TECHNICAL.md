# QR Code Data Sharing - Technical Details

## 🔄 How the QR Code Sharing Works

### Architecture Overview

```
Device A (Sender)                    Device B (Receiver)
─────────────────────────────────────────────────────
    │                                    │
    ├─ QrDataShareService              │
    │  ├─ Generate QR String            │
    │  ├─ Create Session                │
    │  └─ Manage Expiration             │
    │                                    │
    │  QR Code Display                  │
    │  ┌──────────────┐                 │
    │  │ [QR IMAGE]   │                 │
    │  └──────────────┘                 │
    │        │                           │
    │        │ Scan                      │
    │        └──────────────────────────→├─ Parse QR
    │                                    │
    │                          P2PSyncService
    │                         ├─ Verify Session
    │                         ├─ Validate Data
    │                         └─ Sync Events
    │                                    │
    │←─────── Confirmation ─────────────┤
    │
    └─ Update Local Data
```

### Session Lifecycle

1. **Creation** (~0s)
   - User taps "Generate QR Code"
   - Session ID generated (UUID v4)
   - Session stored in memory
   - QR string encoded (base64)

2. **Active** (~0-300s)
   - QR code displayed on screen
   - Other device scans the code
   - Session remains active

3. **Sync** (~sync point)
   - Other device verifies QR
   - Session matched
   - Data transfer initiated
   - Confirmations exchanged

4. **Expiration** (~300s)
   - Automatic cleanup
   - Session removed from memory
   - Stream closed
   - Resources freed

### Data Flow

```
SharedDataPayload {
  sessionId: "550e8400-e29b-41d4-a716-446655440000"
  deviceName: "My Phone"
  data: {
    notes: [...],
    tasks: [...],
    calendar: [...]
  }
  createdAt: "2024-07-24T10:30:00Z"
  expiresInSeconds: 300
}
        │
        └─→ JSON.encode()
            │
            └─→ UTF-8.encode()
                │
                └─→ base64.encode()
                    │
                    └─→ QrImage(data: qrString)
```

---

## 🔐 Security Implementation

### Current Security (Session-based)
```dart
// Session ID prevents unauthorized access
final sessionId = const Uuid().v4();

// Automatic expiration limits window of vulnerability
Timer(Duration(seconds: payload.expiresInSeconds), () {
  _activeSessions.remove(payload.sessionId);
});

// Stream-based verification
Stream<SharedDataPayload> listenForSync(String sessionId) {
  // Only known sessions can receive confirmations
}
```

### Future Security Enhancements
```dart
// Encryption using ChaCha20-Poly1305
final encryptionKey = await generateEncryptionKey();

// HMAC verification
final hmac = generateHmac(qrString, secret);

// Device certificate pinning
verifyDeviceCertificate(certificateHash);
```

---

## 📋 Implementation Details

### QrDataShareService API

#### Generate QR Code
```dart
Future<String> generateQrString({
  required Map<String, dynamic> data,
  required String deviceName,
}) async
```
Returns base64-encoded QR string

#### Verify QR String
```dart
Future<SharedDataPayload?> verifyQrString(String qrString) async
```
Decodes and validates QR string, returns payload or null

#### Listen for Sync
```dart
Stream<SharedDataPayload> listenForSync(String sessionId)
```
Returns stream of sync events for session

#### Confirm Sync
```dart
Future<void> confirmSync(
  String sessionId,
  Map<String, dynamic> syncData
) async
```
Sends sync confirmation

---

## 🔄 P2P Sync Service API

### Device Management
```dart
// Initialize with device identity
Future<void> initialize({
  String? deviceId,
  String? deviceName,
}) async

// Register connected peer
Future<void> registerPeer({
  required String peerId,
  required String peerName,
  required String peerAddress,
}) async

// Remove peer
Future<void> removePeer(String peerId) async

// Get all connected peers
List<dynamic> getConnectedPeers()
```

### Sync Management
```dart
// Queue sync event
Future<void> queueSyncEvent({
  required String type,
  required Map<String, dynamic> payload,
  String? targetDeviceId,
}) async

// Listen for sync
Stream<SyncEvent> listenForSync(String type)
Stream<SyncEvent> listenForAllSync()

// Acknowledge sync
Future<void> acknowledgeSyncEvent(String eventId) async

// Get pending events
List<SyncEvent> getPendingSyncEvents()
```

---

## 🎯 Data Types Supported

### Shareable Data
```dart
{
  'notes': [
    {
      'id': 'note-1',
      'title': 'My Note',
      'content': '...',
      'createdAt': '...',
      'updatedAt': '...',
      'tags': [...]
    }
  ],
  'tasks': [
    {
      'id': 'task-1',
      'title': 'My Task',
      'description': '...',
      'dueDate': '...',
      'priority': 'high',
      'completed': false
    }
  ],
  'calendar': [
    {
      'id': 'event-1',
      'title': 'Meeting',
      'startTime': '...',
      'endTime': '...',
      'description': '...'
    }
  ]
}
```

---

## 📊 Event Structure

```dart
class SyncEvent {
  final String id;                      // Unique event ID
  final String sourceDeviceId;          // Sending device
  final String targetDeviceId;          // Receiving device (or 'broadcast')
  final String type;                    // 'notes', 'tasks', 'calendar', etc.
  final Map<String, dynamic> payload;   // Actual data
  final DateTime timestamp;             // When created
  final bool isAcknowledged;           // Delivery confirmation
}
```

---

## 🔌 Integration Points

### To Implement QR Scanner
```dart
// In qr_data_share_widget.dart
OutlinedButton.icon(
  onPressed: () {
    // TODO: Use mobile_scanner to scan QR
    // 1. Open camera scanner
    // 2. Detect QR code
    // 3. Call verifyQrString()
    // 4. Trigger sync
  },
  icon: const Icon(Icons.camera_alt_rounded),
  label: const Text('Scan QR Code'),
)
```

### To Implement Real-time Sync
```dart
// Add WebSocket support
class WebSocketP2PSync {
  Future<void> connectToPeer(String peerAddress) async {
    // 1. Establish WebSocket connection
    // 2. Share device info
    // 3. Listen for sync events
    // 4. Send pending events
  }
  
  Future<void> sendSyncEvent(SyncEvent event) async {
    // Serialize and send via WebSocket
  }
}
```

---

## 🧪 Testing Scenarios

### Test 1: Generate QR Code
```
1. Launch app
2. Log in
3. Navigate to Settings → Share
4. Enter device name
5. Click "Generate QR Code"
6. Verify QR code appears
7. Click "Generate New Code"
8. Verify new code generated
```

### Test 2: Session Expiration
```
1. Generate QR code
2. Wait 5 minutes
3. Try to scan code
4. Verify "Session Expired" message
```

### Test 3: Multiple Sessions
```
1. Generate 3 QR codes quickly
2. Verify all are displayable
3. Verify all have unique session IDs
4. Verify proper cleanup after expiration
```

### Test 4: Data Integrity
```
1. Generate QR code with sample data
2. Decode QR string
3. Verify data matches original
4. Verify no data corruption
```

---

## 📈 Performance Considerations

### Memory Usage
- Session storage: ~2KB per session
- QR string encoding: ~1-2KB per code
- Stream controllers: ~1KB each

### Processing Time
- QR generation: ~100-200ms
- Base64 encoding: ~10-50ms
- Session creation: ~5-10ms

### Recommendations
- Limit active sessions to 10-20
- Auto-cleanup after 5 minutes
- Use lazy initialization for streams
- Cache QR strings if regenerating frequently

---

## 🚀 Future Enhancements

1. **Compression**: Compress data before QR encoding
2. **Chunking**: Support large data transfers via multiple QR codes
3. **Retry Logic**: Automatic retry on sync failure
4. **Bandwidth Management**: Throttle sync events
5. **Conflict Resolution**: Handle simultaneous edits
6. **Version Control**: Track data version for merge strategies

---

## 📝 References

- **QR Format**: Base64-encoded JSON
- **Session ID**: UUID v4
- **Encoding**: UTF-8 + Base64
- **Expiration**: 5 minutes (configurable)
- **Max Data**: ~2.5KB (QR v40)

---

**For implementation questions, refer to the source code comments in:**
- `lib/core/services/qr_data_share_service.dart`
- `lib/core/services/p2p_sync_service.dart`
