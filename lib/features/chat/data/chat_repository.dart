import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/myday_database.dart';

class CallLogItem {
  final String id;
  final String contactKey;
  final String nickname;
  final String type; // 'outgoing' | 'incoming' | 'missed'
  final int durationSeconds;
  final int timestamp;

  const CallLogItem({
    required this.id,
    required this.contactKey,
    required this.nickname,
    required this.type,
    required this.durationSeconds,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'contactKey': contactKey,
        'nickname': nickname,
        'type': type,
        'durationSeconds': durationSeconds,
        'timestamp': timestamp,
      };

  factory CallLogItem.fromJson(Map<String, dynamic> json) => CallLogItem(
        id: json['id'] as String,
        contactKey: json['contactKey'] as String,
        nickname: json['nickname'] as String? ?? (json['contactKey'] as String),
        type: json['type'] as String? ?? 'outgoing',
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );
}

class ChatContact {
  final String id;
  final String accountId;
  final String contactKey;
  final String nickname;
  final int avatarColor;
  final String lastMessage;
  final int lastMessageTime;
  final int createdAt;

  const ChatContact({
    required this.id,
    required this.accountId,
    required this.contactKey,
    required this.nickname,
    this.avatarColor = 0,
    this.lastMessage = '',
    this.lastMessageTime = 0,
    required this.createdAt,
  });

  factory ChatContact.fromRow(QueryRow row) {
    return ChatContact(
      id: row.read<String>('id'),
      accountId: row.read<String>('account_id'),
      contactKey: row.read<String>('contact_key'),
      nickname: row.read<String>('nickname'),
      avatarColor: row.read<int>('avatar_color'),
      lastMessage: row.read<String>('last_message'),
      lastMessageTime: row.read<int>('last_message_time'),
      createdAt: row.read<int>('created_at'),
    );
  }
}

class ChatMessage {
  final String id;
  final String accountId;
  final String contactKey;
  final String senderKey;
  final String receiverKey;
  final String content;
  final String? mediaPath;
  final String? mediaType;
  final bool isOutgoing;
  final String status;
  final int timestamp;

  const ChatMessage({
    required this.id,
    required this.accountId,
    required this.contactKey,
    required this.senderKey,
    required this.receiverKey,
    required this.content,
    this.mediaPath,
    this.mediaType,
    required this.isOutgoing,
    required this.status,
    required this.timestamp,
  });

  bool get isImage => mediaType == 'image' || (mediaPath != null && mediaPath!.isNotEmpty);
  bool get isSending => status == 'sending';
  bool get isSent => status == 'sent' || status == 'delivered';

  factory ChatMessage.fromRow(QueryRow row) {
    return ChatMessage(
      id: row.read<String>('id'),
      accountId: row.read<String>('account_id'),
      contactKey: row.read<String>('contact_key'),
      senderKey: row.read<String>('sender_key'),
      receiverKey: row.read<String>('receiver_key'),
      content: row.read<String>('content'),
      mediaPath: row.readNullable<String>('media_path'),
      mediaType: row.readNullable<String>('media_type'),
      isOutgoing: row.read<int>('is_outgoing') == 1,
      status: row.read<String>('status'),
      timestamp: row.read<int>('timestamp'),
    );
  }
}

class ChatRepository {
  final MyDayDatabase db;
  static const _uuid = Uuid();

  final _messagesUpdateController = StreamController<String>.broadcast();
  Stream<String> get onChatUpdated => _messagesUpdateController.stream;

  ChatRepository(this.db);

  void dispose() {
    _messagesUpdateController.close();
  }

  /// Normalizes and formats friend key / 10-digit SIM phone number
  static String formatKey(String rawKey) {
    final cleaned = rawKey.trim();
    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 10) {
      return digitsOnly.substring(digitsOnly.length - 10);
    }
    final upper = cleaned.toUpperCase();
    if (upper.startsWith('DESK-KEY-')) {
      return upper.toLowerCase();
    }
    if (digitsOnly.length >= 7) {
      return digitsOnly;
    }
    return 'desk-key-${upper.replaceAll(RegExp(r'[^A-Z0-9]'), '')}'.toLowerCase();
  }

  Future<List<ChatContact>> getContacts(String accountId) async {
    final rows = await db.customSelect(
      '''
      SELECT * FROM chat_contacts 
      WHERE account_id = ? 
      ORDER BY last_message_time DESC, created_at DESC
      ''',
      variables: [Variable(accountId)],
    ).get();

    return rows.map(ChatContact.fromRow).toList();
  }

  Future<ChatContact?> getContact(String accountId, String contactKey) async {
    final cleanKey = contactKey.trim().toLowerCase();
    final digits = cleanKey.replaceAll(RegExp(r'\D'), '');
    final digits10 = digits.length >= 10 ? digits.substring(digits.length - 10) : '';

    final rows = await db.customSelect(
      '''
      SELECT * FROM chat_contacts 
      WHERE account_id = ? AND (
        lower(contact_key) = ? 
        OR (? != '' AND contact_key LIKE '%' || ?)
      ) LIMIT 1
      ''',
      variables: [
        Variable(accountId),
        Variable(cleanKey),
        Variable(digits10),
        Variable(digits10),
      ],
    ).get();

    if (rows.isEmpty) return null;
    return ChatContact.fromRow(rows.first);
  }

  Future<ChatContact> addOrUpdateContact({
    required String accountId,
    required String contactKey,
    required String nickname,
    int? avatarColor,
  }) async {
    final cleanKey = formatKey(contactKey);
    final existing = await getContact(accountId, cleanKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (existing != null) {
      final updatedName = nickname.trim().isNotEmpty ? nickname.trim() : existing.nickname;
      await db.customUpdate(
        'UPDATE chat_contacts SET nickname = ? WHERE id = ?',
        variables: [Variable(updatedName), Variable(existing.id)],
      );
      _messagesUpdateController.add(cleanKey);
      return ChatContact(
        id: existing.id,
        accountId: accountId,
        contactKey: cleanKey,
        nickname: updatedName,
        avatarColor: existing.avatarColor,
        lastMessage: existing.lastMessage,
        lastMessageTime: existing.lastMessageTime,
        createdAt: existing.createdAt,
      );
    }

    final id = _uuid.v4().substring(0, 8);
    final color = avatarColor ?? (cleanKey.hashCode.abs() % 6);
    final name = nickname.trim().isNotEmpty ? nickname.trim() : cleanKey;

    await db.customInsert(
      '''
      INSERT INTO chat_contacts (id, account_id, contact_key, nickname, avatar_color, last_message, last_message_time, created_at)
      VALUES (?, ?, ?, ?, ?, '', ?, ?)
      ''',
      variables: [
        Variable(id),
        Variable(accountId),
        Variable(cleanKey),
        Variable(name),
        Variable(color),
        Variable(now),
        Variable(now),
      ],
    );

    _messagesUpdateController.add(cleanKey);
    return ChatContact(
      id: id,
      accountId: accountId,
      contactKey: cleanKey,
      nickname: name,
      avatarColor: color,
      lastMessage: '',
      lastMessageTime: now,
      createdAt: now,
    );
  }

  Future<void> deleteContact(String contactId) async {
    await db.customStatement('DELETE FROM chat_contacts WHERE id = ?', [contactId]);
    _messagesUpdateController.add('*');
  }

  Future<List<ChatMessage>> getMessages(String accountId, String contactKey) async {
    final cleanKey = formatKey(contactKey);
    final digits = cleanKey.replaceAll(RegExp(r'\D'), '');
    final digits10 = digits.length >= 10 ? digits.substring(digits.length - 10) : '';

    final rows = await db.customSelect(
      '''
      SELECT * FROM chat_messages 
      WHERE account_id = ? AND (
        lower(contact_key) = ? 
        OR (? != '' AND (
          contact_key LIKE '%' || ? 
          OR sender_key LIKE '%' || ? 
          OR receiver_key LIKE '%' || ?
        ))
      ) AND is_deleted = 0 
      ORDER BY timestamp ASC
      ''',
      variables: [
        Variable(accountId),
        Variable(cleanKey),
        Variable(digits10),
        Variable(digits10),
        Variable(digits10),
        Variable(digits10),
      ],
    ).get();

    return rows.map(ChatMessage.fromRow).toList();
  }

  Future<ChatMessage> saveOutgoingMessage({
    required String accountId,
    required String senderKey,
    required String receiverKey,
    required String content,
    String? mediaPath,
    String? mediaType,
    String status = 'sending',
    String? customId,
    int? timestamp,
  }) async {
    final id = customId ?? _uuid.v4();
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final cleanReceiver = formatKey(receiverKey);
    final cleanSender = formatKey(senderKey);

    await db.customInsert(
      '''
      INSERT INTO chat_messages (
        id, account_id, contact_key, sender_key, receiver_key,
        content, media_path, media_type, is_outgoing, status, timestamp, is_deleted
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, 0)
      ''',
      variables: [
        Variable(id),
        Variable(accountId),
        Variable(cleanReceiver),
        Variable(cleanSender),
        Variable(cleanReceiver),
        Variable(content),
        Variable(mediaPath),
        Variable(mediaType),
        Variable(status),
        Variable(now),
      ],
    );

    // Update last message in contact
    final preview = (mediaType == 'image' || mediaPath != null) ? '📷 Photo' : content;
    await db.customUpdate(
      'UPDATE chat_contacts SET last_message = ?, last_message_time = ? WHERE account_id = ? AND lower(contact_key) = ?',
      variables: [
        Variable(preview),
        Variable(now),
        Variable(accountId),
        Variable(cleanReceiver),
      ],
    );

    _messagesUpdateController.add(cleanReceiver);
    _messagesUpdateController.add('*');

    return ChatMessage(
      id: id,
      accountId: accountId,
      contactKey: cleanReceiver,
      senderKey: cleanSender,
      receiverKey: cleanReceiver,
      content: content,
      mediaPath: mediaPath,
      mediaType: mediaType,
      isOutgoing: true,
      status: status,
      timestamp: now,
    );
  }

  Future<void> updateMessageStatus(String messageId, String status) async {
    await db.customUpdate(
      'UPDATE chat_messages SET status = ? WHERE id = ?',
      variables: [Variable(status), Variable(messageId)],
    );
    _messagesUpdateController.add('*');
  }

  Future<ChatMessage> saveIncomingMessage({
    required String accountId,
    required String senderKey,
    required String receiverKey,
    required String content,
    String? mediaPath,
    String? mediaType,
    int? timestamp,
    String? customId,
    String status = 'delivered',
  }) async {
    final id = customId ?? _uuid.v4();
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final cleanSender = formatKey(senderKey);
    final cleanReceiver = formatKey(receiverKey);

    // Auto-create contact if not exists
    await addOrUpdateContact(
      accountId: accountId,
      contactKey: cleanSender,
      nickname: cleanSender,
    );

    await db.customInsert(
      '''
      INSERT OR REPLACE INTO chat_messages (
        id, account_id, contact_key, sender_key, receiver_key,
        content, media_path, media_type, is_outgoing, status, timestamp, is_deleted
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, 0)
      ''',
      variables: [
        Variable(id),
        Variable(accountId),
        Variable(cleanSender),
        Variable(cleanSender),
        Variable(cleanReceiver),
        Variable(content),
        Variable(mediaPath),
        Variable(mediaType),
        Variable(status),
        Variable(now),
      ],
    );

    final preview = (mediaType == 'image' || mediaPath != null) ? '📷 Photo' : content;
    await db.customUpdate(
      'UPDATE chat_contacts SET last_message = ?, last_message_time = ? WHERE account_id = ? AND lower(contact_key) = ?',
      variables: [
        Variable(preview),
        Variable(now),
        Variable(accountId),
        Variable(cleanSender),
      ],
    );

    _messagesUpdateController.add(cleanSender);
    _messagesUpdateController.add('*');

    return ChatMessage(
      id: id,
      accountId: accountId,
      contactKey: cleanSender,
      senderKey: cleanSender,
      receiverKey: cleanReceiver,
      content: content,
      mediaPath: mediaPath,
      mediaType: mediaType,
      isOutgoing: false,
      status: 'delivered',
      timestamp: now,
    );
  }

  Future<void> deleteMessage(String messageId) async {
    await db.customUpdate(
      'UPDATE chat_messages SET is_deleted = 1 WHERE id = ?',
      variables: [Variable(messageId)],
    );
    _messagesUpdateController.add('*');
  }

  Future<void> clearChatHistory(String accountId, String contactKey) async {
    final cleanKey = contactKey.trim().toLowerCase();
    await db.customStatement(
      'DELETE FROM chat_messages WHERE account_id = ? AND lower(contact_key) = ?',
      [accountId, cleanKey],
    );
    await db.customUpdate(
      'UPDATE chat_contacts SET last_message = "", last_message_time = ? WHERE account_id = ? AND lower(contact_key) = ?',
      variables: [
        Variable(DateTime.now().millisecondsSinceEpoch),
        Variable(accountId),
        Variable(cleanKey),
      ],
    );
    _messagesUpdateController.add(cleanKey);
  }

  // --- Call Logs / Phone Call Registry ---
  Future<List<CallLogItem>> getCallLogs(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('myday_call_logs_$accountId');
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => CallLogItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addCallLog(String accountId, CallLogItem item) async {
    final current = await getCallLogs(accountId);
    current.insert(0, item);
    // Keep max 100 recent calls
    if (current.length > 100) {
      current.removeRange(100, current.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'myday_call_logs_$accountId',
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
    _messagesUpdateController.add('call_logs');
  }

  Future<void> clearCallLogs(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('myday_call_logs_$accountId');
    _messagesUpdateController.add('call_logs');
  }
}
