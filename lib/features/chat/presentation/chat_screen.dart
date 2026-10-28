import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../data/chat_repository.dart';
import '../services/call_audio_service.dart';
import '../services/chat_socket_service.dart';
import 'conversation_screen.dart';
import 'widgets/phone_call_dialog.dart';

enum CallViewTab { dialpad, phonebook, messages, recents }

class CallScreen extends StatefulWidget {
  final ChatRepository chatRepository;
  final UserSession session;

  const CallScreen({
    super.key,
    required this.chatRepository,
    required this.session,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

typedef ChatScreen = CallScreen;

class _CallScreenState extends State<CallScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatSocketService _socketService = ChatSocketService();

  // Dial pad opens first by default
  CallViewTab _currentTab = CallViewTab.dialpad;

  List<ChatContact> _allContacts = [];
  List<ChatContact> _filteredContacts = [];
  List<CallLogItem> _callLogs = [];
  bool _isLoading = true;

  // Dialpad state
  String _dialedNumber = '';

  StreamSubscription<CallSignal>? _callSignalSub;
  StreamSubscription<String>? _chatUpdateSub;

  @override
  void initState() {
    super.initState();
    _initSocketAndLoad();

    _chatUpdateSub = widget.chatRepository.onChatUpdated.listen((_) {
      if (mounted) {
        _loadContacts();
        _loadCallLogs();
      }
    });

    // Incoming calls are handled globally by MyDayApp listener
  }

  @override
  void dispose() {
    _searchController.dispose();
    _callSignalSub?.cancel();
    _chatUpdateSub?.cancel();
    super.dispose();
  }

  Future<void> _initSocketAndLoad() async {
    // 1. Immediately load contacts so UI renders without waiting for network/socket
    await _loadContacts();
    unawaited(_loadCallLogs());

    if (!widget.session.isCloud) return;

    // 2. Initialize socket asynchronously with timeout
    try {
      await _socketService.initialize(
        accountId: widget.session.accountId,
        identityKey: widget.session.phoneNumber,
        userName: widget.session.name,
        chatRepository: widget.chatRepository,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await widget.chatRepository
          .getContacts(widget.session.accountId)
          .timeout(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _allContacts = contacts;
          _filterContacts();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCallLogs() async {
    final logs = await widget.chatRepository.getCallLogs(widget.session.accountId);
    if (mounted) {
      setState(() {
        _callLogs = logs;
      });
    }
  }

  void _filterContacts() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredContacts = List.from(_allContacts);
    } else {
      _filteredContacts = _allContacts.where((c) {
        return c.nickname.toLowerCase().contains(q) || c.contactKey.toLowerCase().contains(q);
      }).toList();
    }
  }

  void _showAddFriendDialog({String? initialNumber}) {
    final keyController = TextEditingController(text: initialNumber ?? '');
    final nameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.person_add_alt_1_rounded, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            Text('Add Contact to Phonebook', style: AppTypography.h3.copyWith(color: context.appText)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '10-digit Phone Number:',
              style: TextStyle(color: context.appMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.appBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appLine),
              ),
              child: TextField(
                controller: keyController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: context.appText, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'e.g. 9841234567',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Contact Name / Nickname:',
              style: TextStyle(color: context.appMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.appBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appLine),
              ),
              child: TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: context.appText),
                decoration: const InputDecoration(
                  hintText: 'e.g. Maya Sharma',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final rawKey = keyController.text.trim();
              if (rawKey.isEmpty) return;
              final formattedKey = ChatRepository.formatKey(rawKey);
              final nickname = nameController.text.trim().isNotEmpty
                  ? nameController.text.trim()
                  : formattedKey;

              await widget.chatRepository.addOrUpdateContact(
                accountId: widget.session.accountId,
                contactKey: formattedKey,
                nickname: nickname,
              );
              await _loadContacts();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                UndoToast.show(context, message: 'Saved contact: $nickname ($formattedKey)');
              }
            },
            child: const Text('Save Contact'),
          ),
        ],
      ),
    );
  }

  void _showRelaySettingsDialog() {
    final relayController = TextEditingController(text: _socketService.relayUrl);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return AlertDialog(
            backgroundColor: modalCtx.appSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(AppIcons.phoneCall, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Call Network & Relay Settings',
                    style: AppTypography.h3.copyWith(color: modalCtx.appText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Socket.IO Relay Address:',
                    style: TextStyle(color: modalCtx.appMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: modalCtx.appBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: modalCtx.appLine),
                    ),
                    child: TextField(
                      controller: relayController,
                      style: TextStyle(color: modalCtx.appText, fontFamily: 'monospace', fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'http://127.0.0.1:3000',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Supabase Realtime Broadcast is active for worldwide calling.',
                            style: TextStyle(fontSize: 12, color: AppColors.successGreen, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: modalCtx.appLine),
                  const SizedBox(height: 8),
                  Text(
                    'Host Local Wi-Fi Relay on this Device:',
                    style: TextStyle(color: modalCtx.appText, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enables direct P2P call and chat relay for devices connected to your Wi-Fi.',
                    style: TextStyle(color: modalCtx.appMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<bool>(
                    valueListenable: _socketService.isLocalHostRunning,
                    builder: (_, isRunning, __) {
                      return Row(
                        children: [
                          Expanded(
                            child: isRunning
                                ? ValueListenableBuilder<String?>(
                                    valueListenable: _socketService.localHostIp,
                                    builder: (_, ip, __) {
                                      return Text(
                                        'Hosting at: http://${ip ?? "localhost"}:3000',
                                        style: const TextStyle(
                                          color: AppColors.successGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  )
                                : const Text(
                                    'Relay Host: Stopped',
                                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                          ),
                          Switch(
                            value: isRunning,
                            activeThumbColor: AppColors.accent,
                            onChanged: (val) async {
                              if (val) {
                                await _socketService.startLocalWifiRelayHost();
                                relayController.text = _socketService.relayUrl;
                              } else {
                                await _socketService.stopLocalWifiRelayHost();
                              }
                              setModalState(() {});
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await _socketService.updateRelayUrl(relayController.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!mounted) return;
                  UndoToast.show(context, message: 'Relay server updated');
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCloudAccountPrompt() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.cloud_outlined, color: AppColors.accent, size: 24),
            const SizedBox(width: 8),
            Text('Cloud Account Required', style: AppTypography.h3.copyWith(color: context.appText)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pocketdesk Call connects users via secure cloud signaling. With a Cloud Account you receive a personal 10-digit number to make and receive calls anywhere.',
              style: TextStyle(color: context.appMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appLine),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_iphone_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your call number will be automatically generated and linked to your profile.',
                      style: TextStyle(fontSize: 12, color: context.appText, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              UndoToast.show(context, message: 'Open Profile → Convert to Cloud Account');
            },
            child: const Text('Get Cloud Account'),
          ),
        ],
      ),
    );
  }

  void _openConversation(ChatContact contact) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(
          chatRepository: widget.chatRepository,
          accountId: widget.session.accountId,
          myIdentityKey: widget.session.phoneNumber,
          myName: widget.session.name,
          contact: contact,
        ),
      ),
    );
  }

  void _callContact(String phoneNumber, String nickname) {
    PhoneCallDialog.startCall(
      context: context,
      phoneNumber: phoneNumber,
      contactName: nickname,
      accountId: widget.session.accountId,
      chatRepository: widget.chatRepository,
      myNumber: widget.session.phoneNumber,
      myName: widget.session.name,
    );
  }

  // --- Dialpad Handlers ---
  void _onDialpadKey(String char) {
    if (_dialedNumber.length >= 15) return;
    HapticFeedback.lightImpact();
    try {
      CallAudioService.instance.playDialpadTone(char);
    } catch (_) {}
    setState(() {
      _dialedNumber += char;
    });
  }

  void _onDialpadBackspace() {
    if (_dialedNumber.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _dialedNumber = _dialedNumber.substring(0, _dialedNumber.length - 1);
    });
  }

  void _onDialpadClear() {
    setState(() {
      _dialedNumber = '';
    });
  }

  void _simulateIncomingCall({String callerName = 'Akash Sharma', String callerNumber = '9860124892'}) {
    UndoToast.show(context, message: 'Incoming call test arriving in 2s...');
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final testSignal = CallSignal(
        type: CallSignalType.invite,
        callId: 'sim_${DateTime.now().millisecondsSinceEpoch}',
        callerNumber: callerNumber,
        callerName: callerName,
        calleeNumber: widget.session.phoneNumber,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      PhoneCallDialog.showIncomingCall(
        context: context,
        invite: testSignal,
        accountId: widget.session.accountId,
        chatRepository: widget.chatRepository,
        myNumber: widget.session.phoneNumber,
        myName: widget.session.name,
      );
    });
  }

  void _handleDialpadCall() {
    if (_dialedNumber.trim().isEmpty) return;
    final num = ChatRepository.formatKey(_dialedNumber);
    if (num == '*100#' || num == '*123#' || num == '*000#' || num.toLowerCase() == 'test' || num == '9999999999') {
      _simulateIncomingCall();
      return;
    }
    final match = _allContacts.where((c) => c.contactKey == num).firstOrNull;
    final name = match?.nickname ?? num;
    _callContact(num, name);
  }

  void _handleDialpadChat() async {
    if (_dialedNumber.trim().isEmpty) return;
    final num = ChatRepository.formatKey(_dialedNumber);
    final contact = await widget.chatRepository.addOrUpdateContact(
      accountId: widget.session.accountId,
      contactKey: num,
      nickname: num,
    );
    _openConversation(contact);
  }

  @override
  Widget build(BuildContext context) {
    final myPhone = widget.session.phoneNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Flexible(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  if (widget.session.isCloud) {
                    Clipboard.setData(ClipboardData(text: myPhone));
                    UndoToast.show(context, message: 'Phone number $myPhone copied to clipboard!');
                  } else {
                    _showCloudAccountPrompt();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.session.isCloud ? AppColors.accent.withValues(alpha: 0.45) : context.appLine,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(AppIcons.phone, size: 14, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.session.isCloud ? 'ID: $myPhone' : 'Call ID: Cloud Only',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: widget.session.isCloud ? 'monospace' : null,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: widget.session.isCloud ? AppColors.accent : context.appMuted,
                          ),
                        ),
                      ),
                      if (widget.session.isCloud) ...[
                        const SizedBox(width: 6),
                        Icon(AppIcons.copy, size: 12, color: context.appMuted),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: _socketService.isConnected,
              builder: (context, connected, _) {
                return GestureDetector(
                  onTap: _showRelaySettingsDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: (connected ? AppColors.successGreen : AppColors.amber).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: connected ? AppColors.successGreen : AppColors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          connected ? 'Call Online' : 'Standby',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: connected ? AppColors.successGreen : AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        if (!widget.session.isCloud) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_outlined, color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Account Required',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'To get your 10-digit call number and make voice calls, connect a free Cloud account.',
                        style: TextStyle(fontSize: 12, color: context.appMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _showCloudAccountPrompt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appLine),
          ),
          child: Row(
            children: [
              _buildSegmentButton(
                tab: CallViewTab.dialpad,
                title: 'Dialpad',
                icon: Icons.dialpad_rounded,
              ),
              _buildSegmentButton(
                tab: CallViewTab.phonebook,
                title: 'Phonebook',
                icon: Icons.contacts_rounded,
                count: _allContacts.length,
              ),
              _buildSegmentButton(
                tab: CallViewTab.messages,
                title: 'Messages',
                icon: Icons.chat_bubble_rounded,
                count: _allContacts.where((c) => c.lastMessage.isNotEmpty).length,
              ),
              _buildSegmentButton(
                tab: CallViewTab.recents,
                title: 'Recents',
                icon: Icons.history_rounded,
                count: _callLogs.length,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _currentTab == CallViewTab.dialpad
              ? _buildDialpadView()
              : SingleChildScrollView(
                  child: _currentTab == CallViewTab.phonebook
                      ? _buildPhonebookView()
                      : _currentTab == CallViewTab.messages
                          ? _buildMessagesView()
                          : _buildRecentCallsView(),
                ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required CallViewTab tab,
    required String title,
    required IconData icon,
    int? count,
  }) {
    final isSelected = _currentTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = tab),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : context.appMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : context.appMuted,
                  ),
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.28) : context.appSurface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : context.appMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialpadView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keySize = (constraints.maxWidth / 3).clamp(64.0, 92.0);
        final keyHeight = ((constraints.maxHeight - 168) / 5).clamp(52.0, 76.0);

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        _dialedNumber.isEmpty ? 'Type 10-digit number...' : _dialedNumber,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: _dialedNumber.isEmpty ? 18 : 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: _dialedNumber.isEmpty ? 0.4 : 2,
                          color: _dialedNumber.isEmpty ? context.appMuted : context.appText,
                        ),
                      ),
                    ),
                  ),
                  if (_dialedNumber.isNotEmpty)
                    IconButton(
                      onPressed: _onDialpadBackspace,
                      onLongPress: _onDialpadClear,
                      icon: Icon(Icons.backspace_outlined, size: 22, color: context.appMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDialRow(['1', '2', '3'], ['', 'ABC', 'DEF'], keySize, keyHeight),
                  _buildDialRow(['4', '5', '6'], ['GHI', 'JKL', 'MNO'], keySize, keyHeight),
                  _buildDialRow(['7', '8', '9'], ['PQRS', 'TUV', 'WXYZ'], keySize, keyHeight),
                  _buildDialRow(['*', '0', '#'], ['', '+', ''], keySize, keyHeight),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircularIconButton(
                  icon: Icons.person_add_rounded,
                  size: 52,
                  iconSize: 22,
                  customColor: context.appSurface2,
                  iconColor: context.appText,
                  onPressed: _dialedNumber.isNotEmpty
                      ? () => _showAddFriendDialog(initialNumber: _dialedNumber)
                      : null,
                ),
                GestureDetector(
                  onTap: _handleDialpadCall,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _dialedNumber.isNotEmpty
                          ? AppColors.successGreen
                          : AppColors.successGreen.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      boxShadow: _dialedNumber.isNotEmpty
                          ? [
                              BoxShadow(
                                color: AppColors.successGreen.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: const Icon(Icons.phone_rounded, color: Colors.white, size: 32),
                  ),
                ),
                CircularIconButton(
                  icon: Icons.chat_rounded,
                  size: 52,
                  iconSize: 22,
                  customColor: context.appSurface2,
                  iconColor: AppColors.accent,
                  onPressed: _dialedNumber.isNotEmpty ? _handleDialpadChat : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildDialRow(List<String> digits, List<String> letters, double width, double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) => _buildDialKey(digits[i], letters[i], width, height)),
    );
  }

  Widget _buildDialKey(String digit, String letters, [double width = 76, double height = 64]) {
    return GestureDetector(
      onTap: () => _onDialpadKey(digit),
      onLongPress: digit == '0' ? () => _onDialpadKey('+') : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  digit,
                  style: TextStyle(
                    fontSize: height >= 64 ? 28 : 22,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    color: context.appText,
                  ),
                ),
                if (letters.isNotEmpty)
                  Text(
                    letters,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      letterSpacing: 1.4,
                      color: context.appMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. Phonebook / Contacts View ---
  Widget _buildPhonebookView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.appLine),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(_filterContacts),
                  style: TextStyle(color: context.appText),
                  decoration: InputDecoration(
                    icon: Icon(AppIcons.search, size: 18, color: context.appMuted),
                    hintText: 'Search contacts or numbers...',
                    hintStyle: TextStyle(color: context.appMuted, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              icon: const Icon(Icons.add_call, size: 18),
              label: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              onPressed: () => _showAddFriendDialog(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_isLoading) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
        ] else if (_filteredContacts.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.appLine),
            ),
            child: Column(
              children: [
                const Icon(Icons.contact_phone_outlined, size: 44, color: AppColors.muted),
                const SizedBox(height: 12),
                Text(
                  _allContacts.isEmpty ? 'Phonebook is Empty' : 'No Contacts Found',
                  style: AppTypography.h4.copyWith(color: context.appText),
                ),
                const SizedBox(height: 6),
                Text(
                  _allContacts.isEmpty
                      ? 'Save friends with their 10-digit number to call or message them instantly.'
                      : 'Try searching with another name or phone number.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.appMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('Add New Contact'),
                  onPressed: () => _showAddFriendDialog(),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredContacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final contact = _filteredContacts[index];
              return _buildContactCard(contact);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildContactCard(ChatContact contact) {
    const avatarColors = [
      Color(0xFFE57373),
      Color(0xFF81C784),
      Color(0xFF64B5F6),
      Color(0xFFFFB74D),
      Color(0xFFBA68C8),
      Color(0xFF4DB6AC),
    ];
    final color = avatarColors[contact.avatarColor % avatarColors.length];
    final initial = contact.nickname.isNotEmpty ? contact.nickname.substring(0, 1).toUpperCase() : '#';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appLine),
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _openConversation(contact),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: color,
              child: Text(
                initial,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & 10-Digit Phone Number
          Expanded(
            child: GestureDetector(
              onTap: () => _openConversation(contact),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.nickname,
                    style: TextStyle(
                      color: context.appText,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 12, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        contact.contactKey,
                        style: TextStyle(
                          color: context.appMuted,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons: Call & Message
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_rounded, color: AppColors.successGreen, size: 18),
                ),
                tooltip: 'Voice Call',
                onPressed: () => _callContact(contact.contactKey, contact.nickname),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, color: AppColors.accent, size: 17),
                ),
                tooltip: 'Chat Message',
                onPressed: () => _openConversation(contact),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: context.appMuted, size: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: context.appSurface,
                onSelected: (val) async {
                  if (val == 'delete') {
                    await widget.chatRepository.deleteContact(contact.id);
                    _loadContacts();
                    if (mounted) {
                      UndoToast.show(context, message: 'Removed ${contact.nickname} from Phonebook');
                    }
                  } else if (val == 'copy') {
                    Clipboard.setData(ClipboardData(text: contact.contactKey));
                    if (mounted) {
                      UndoToast.show(context, message: 'Copied ${contact.contactKey} to clipboard');
                    }
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(AppIcons.copy, size: 16),
                        SizedBox(width: 8),
                        Text('Copy Number'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(AppIcons.trash, size: 16, color: AppColors.errorRed),
                        SizedBox(width: 8),
                        Text('Remove Contact', style: TextStyle(color: AppColors.errorRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. Messages View ---
  Widget _buildMessagesView() {
    final activeChats = _allContacts.where((c) => c.lastMessage.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeChats.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.appLine),
            ),
            child: Column(
              children: [
                const Icon(Icons.chat_outlined, size: 44, color: AppColors.muted),
                const SizedBox(height: 12),
                Text(
                  'No Messages Yet',
                  style: AppTypography.h4.copyWith(color: context.appText),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type a 10-digit number in the Dialpad or pick a contact from your Phonebook to start messaging.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.appMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.dialpad_rounded, size: 16),
                  label: const Text('Open Dialpad'),
                  onPressed: () => setState(() => _currentTab = CallViewTab.dialpad),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeChats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final contact = activeChats[index];
              return _buildMessageTile(contact);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMessageTile(ChatContact contact) {
    const avatarColors = [
      Color(0xFFE57373),
      Color(0xFF81C784),
      Color(0xFF64B5F6),
      Color(0xFFFFB74D),
      Color(0xFFBA68C8),
      Color(0xFF4DB6AC),
    ];
    final color = avatarColors[contact.avatarColor % avatarColors.length];
    final initial = contact.nickname.isNotEmpty ? contact.nickname.substring(0, 1).toUpperCase() : '#';
    final timeStr = DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(contact.lastMessageTime));

    return InkWell(
      onTap: () => _openConversation(contact),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appLine),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color,
              child: Text(
                initial,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          contact.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appText,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(color: context.appMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    contact.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.phone_rounded, color: AppColors.successGreen, size: 20),
              tooltip: 'Voice Call',
              onPressed: () => _callContact(contact.contactKey, contact.nickname),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Recent Calls View ---
  Widget _buildRecentCallsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_callLogs.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent Call History (${_callLogs.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.appText),
                ),
              ),
              TextButton.icon(
                icon: const Icon(AppIcons.trash, size: 14, color: AppColors.errorRed),
                label: const Text('Clear', style: TextStyle(color: AppColors.errorRed, fontSize: 12)),
                onPressed: () async {
                  await widget.chatRepository.clearCallLogs(widget.session.accountId);
                  _loadCallLogs();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        if (_callLogs.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.appLine),
            ),
            child: Column(
              children: [
                const Icon(Icons.history_rounded, size: 44, color: AppColors.muted),
                const SizedBox(height: 12),
                Text(
                  'No Recent Calls',
                  style: AppTypography.h4.copyWith(color: context.appText),
                ),
                const SizedBox(height: 6),
                Text(
                  'Placed, received, and missed voice calls will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.appMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.dialpad_rounded, size: 16),
                  label: const Text('Open Dialpad'),
                  onPressed: () => setState(() => _currentTab = CallViewTab.dialpad),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _callLogs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = _callLogs[index];
              return _buildCallLogTile(log);
            },
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildCallLogTile(CallLogItem log) {
    final isMissed = log.type == 'missed' || (log.durationSeconds == 0 && log.type == 'incoming');
    final isOutgoing = log.type == 'outgoing';

    IconData callIcon;
    Color callColor;
    String typeLabel;

    if (isMissed) {
      callIcon = Icons.call_missed_rounded;
      callColor = AppColors.errorRed;
      typeLabel = 'Missed';
    } else if (isOutgoing) {
      callIcon = Icons.call_made_rounded;
      callColor = AppColors.accent;
      typeLabel = 'Outgoing (${_formatDuration(log.durationSeconds)})';
    } else {
      callIcon = Icons.call_received_rounded;
      callColor = AppColors.successGreen;
      typeLabel = 'Incoming (${_formatDuration(log.durationSeconds)})';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
    final dateStr = DateFormat('MMM d, h:mm a').format(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appLine),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: callColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(callIcon, color: callColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isMissed ? AppColors.errorRed : context.appText,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: callColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('•', style: TextStyle(color: context.appMuted, fontSize: 10)),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11, color: context.appMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Compact Action Buttons: Redial and Message (Zero overflow footprint)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.phone_rounded, color: AppColors.successGreen, size: 19),
                tooltip: 'Call Back',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => _callContact(log.contactKey, log.nickname),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.accent, size: 17),
                tooltip: 'Send Message',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final contact = await widget.chatRepository.addOrUpdateContact(
                    accountId: widget.session.accountId,
                    contactKey: log.contactKey,
                    nickname: log.nickname,
                  );
                  _openConversation(contact);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
