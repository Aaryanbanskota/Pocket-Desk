import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../data/chat_repository.dart';
import '../../services/call_audio_service.dart';
import '../../services/chat_socket_service.dart';
import '../../services/voice_call_audio_service.dart';

Route<void> _callRoute(Widget page) {
  return PageRouteBuilder<void>(
    opaque: true,
    fullscreenDialog: true,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

class PhoneCallDialog extends StatefulWidget {
  final String phoneNumber;
  final String contactName;
  final String accountId;
  final ChatRepository chatRepository;
  final bool isIncoming;
  final String? callId;
  final String myNumber;
  final String myName;

  const PhoneCallDialog({
    super.key,
    required this.phoneNumber,
    required this.contactName,
    required this.accountId,
    required this.chatRepository,
    this.isIncoming = false,
    this.callId,
    this.myNumber = '',
    this.myName = 'Me',
  });

  static Future<void> startCall({
    required BuildContext context,
    required String phoneNumber,
    required String contactName,
    required String accountId,
    required ChatRepository chatRepository,
    String myNumber = '',
    String myName = 'Me',
  }) async {
    try {
      final recorder = AudioRecorder();
      final granted = await recorder.hasPermission();
      await recorder.dispose();
      if (!granted && !Platform.isLinux && !kIsWeb) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required for voice calls.')),
          );
        }
        return;
      }
    } catch (_) {}

    if (!context.mounted) return;
    if (isCallActive) return;
    isCallActive = true;

    final callId = 'call_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final myClean = ChatSocketService.normalize10(myNumber.isNotEmpty ? myNumber : 'me');
    final peerClean = ChatSocketService.normalize10(phoneNumber);

    ChatSocketService().sendCallSignal(
      CallSignal(
        type: CallSignalType.invite,
        callId: callId,
        callerNumber: myClean.isNotEmpty ? myClean : myNumber,
        callerName: myName,
        calleeNumber: peerClean.isNotEmpty ? peerClean : phoneNumber,
        senderNumber: myClean.isNotEmpty ? myClean : myNumber,
        targetNumber: peerClean.isNotEmpty ? peerClean : phoneNumber,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await Navigator.of(context, rootNavigator: true).push(
      _callRoute(
        PhoneCallDialog(
          phoneNumber: peerClean.isNotEmpty ? peerClean : phoneNumber,
          contactName: contactName,
          accountId: accountId,
          chatRepository: chatRepository,
          isIncoming: false,
          callId: callId,
          myNumber: myClean.isNotEmpty ? myClean : myNumber,
          myName: myName,
        ),
      ),
    );
  }

  static bool isCallActive = false;

  static Future<void> showIncomingCall({
    required BuildContext context,
    required CallSignal invite,
    required String accountId,
    required ChatRepository chatRepository,
    required String myNumber,
    required String myName,
  }) async {
    if (isCallActive) return;
    await Navigator.of(context, rootNavigator: true).push(
      _callRoute(
        IncomingCallDialog(
          invite: invite,
          accountId: accountId,
          chatRepository: chatRepository,
          myNumber: myNumber,
          myName: myName,
        ),
      ),
    );
  }

  @override
  State<PhoneCallDialog> createState() => _PhoneCallDialogState();
}

class _PhoneCallDialogState extends State<PhoneCallDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  StreamSubscription<CallSignal>? _signalSub;
  Timer? _connectFallbackTimer;
  Timer? _callDurationTimer;
  Timer? _ringTimeoutTimer;

  bool _isConnected = false;
  bool _isEnding = false;
  int _durationSeconds = 0;
  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _showKeypad = false;
  String _keypadInput = '';
  String _callStatusText = 'Calling...';

  late final String _activeCallId;

  @override
  void initState() {
    super.initState();
    PhoneCallDialog.isCallActive = true;
    _activeCallId = widget.callId ?? 'call_${DateTime.now().millisecondsSinceEpoch}';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _callStatusText = widget.isIncoming ? 'Connected' : 'Calling...';

    if (widget.isIncoming) {
      _isConnected = true;
      _callStatusText = 'Connected';
      _startDurationTimer();
      _listenToSignals();
      VoiceCallAudioService.instance.startVoiceCall(
        callId: _activeCallId,
        myNumber: widget.myNumber,
        peerNumber: widget.phoneNumber,
      );
    } else {
      CallAudioService.instance.startDialingTone();
      _listenToSignals();

      final cleanNum = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (cleanNum.isEmpty || widget.phoneNumber.startsWith('*') || widget.phoneNumber.toLowerCase() == 'test') {
        _connectFallbackTimer = Timer(const Duration(milliseconds: 2500), () {
          if (!mounted || _isConnected) return;
          CallAudioService.instance.stopDialingTone();
          setState(() {
            _isConnected = true;
            _callStatusText = 'Connected';
          });
          _startDurationTimer();
          VoiceCallAudioService.instance.startVoiceCall(
            callId: _activeCallId,
            myNumber: widget.myNumber,
            peerNumber: widget.phoneNumber,
          );
        });
      }

      _ringTimeoutTimer = Timer(const Duration(seconds: 45), () {
        if (!mounted || _isConnected) return;
        _endCall(reason: 'missed');
      });
    }
  }

  void _listenToSignals() {
    _signalSub?.cancel();
    _signalSub = ChatSocketService().onCallSignal.listen((signal) {
      if (!mounted) return;

      final peer10 = ChatSocketService.normalize10(widget.phoneNumber);
      final sender10 = ChatSocketService.normalize10(signal.senderNumber);
      final caller10 = ChatSocketService.normalize10(signal.callerNumber);
      final callee10 = ChatSocketService.normalize10(signal.calleeNumber);
      final target10 = ChatSocketService.normalize10(signal.targetNumber ?? '');

      final isPeerMatch = (signal.callId == _activeCallId) ||
          (peer10.isNotEmpty &&
              (sender10 == peer10 || caller10 == peer10 || callee10 == peer10 || target10 == peer10));

      if (signal.type == CallSignalType.answer) {
        if ((signal.callId == _activeCallId || isPeerMatch) && !_isConnected) {
          CallAudioService.instance.stopDialingTone();
          setState(() {
            _isConnected = true;
            _callStatusText = 'Connected';
          });
          _connectFallbackTimer?.cancel();
          _ringTimeoutTimer?.cancel();
          _startDurationTimer();
          VoiceCallAudioService.instance.startVoiceCall(
            callId: _activeCallId,
            myNumber: widget.myNumber,
            peerNumber: widget.phoneNumber,
          );
        }
      }

      if (signal.type == CallSignalType.end) {
        if (signal.callId == _activeCallId || isPeerMatch) {
          _endCall(peerEnded: true, reason: signal.reason ?? 'ended');
        }
      }
    });
  }

  void _startDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _durationSeconds++;
      });
    });
  }

  @override
  void dispose() {
    CallAudioService.instance.stopAll();
    LocalNotificationService.cancelCallNotification();
    VoiceCallAudioService.instance.stopVoiceCall();
    _signalSub?.cancel();
    _connectFallbackTimer?.cancel();
    _callDurationTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    PhoneCallDialog.isCallActive = false;
    super.dispose();
  }

  Future<void> _endCall({bool peerEnded = false, String reason = 'ended'}) async {
    if (_isEnding) return;
    _isEnding = true;

    CallAudioService.instance.stopAll();
    CallAudioService.instance.playBusySignal();
    VoiceCallAudioService.instance.stopVoiceCall();
    _connectFallbackTimer?.cancel();
    _callDurationTimer?.cancel();
    _ringTimeoutTimer?.cancel();

    if (!peerEnded) {
      final myClean = widget.myNumber.isNotEmpty ? widget.myNumber : 'me';
      ChatSocketService().sendCallSignal(
        CallSignal(
          type: CallSignalType.end,
          callId: _activeCallId,
          callerNumber: widget.isIncoming ? widget.phoneNumber : myClean,
          callerName: widget.isIncoming ? widget.contactName : widget.myName,
          calleeNumber: widget.isIncoming ? myClean : widget.phoneNumber,
          senderNumber: myClean,
          targetNumber: widget.phoneNumber,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          reason: reason,
        ),
      );
    }

    final log = CallLogItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      contactKey: widget.phoneNumber,
      nickname: widget.contactName,
      type: widget.isIncoming ? (_durationSeconds > 0 ? 'incoming' : 'missed') : 'outgoing',
      durationSeconds: _durationSeconds,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await widget.chatRepository.addCallLog(widget.accountId, log);

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.contactName.isNotEmpty
        ? widget.contactName.substring(0, 1).toUpperCase()
        : '#';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: context.appBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_isConnected ? AppColors.successGreen : AppColors.accent).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isConnected ? AppIcons.phoneCall : AppIcons.phone,
                        size: 14,
                        color: _isConnected ? AppColors.successGreen : AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected ? 'Voice call' : 'Calling',
                        style: TextStyle(
                          color: _isConnected ? AppColors.successGreen : AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: _isConnected ? const AlwaysStoppedAnimation(1.0) : _pulseAnimation,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.16),
                      border: Border.all(
                        color: _isConnected ? AppColors.successGreen : AppColors.accent,
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: context.appText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  widget.contactName,
                  style: AppTypography.h2.copyWith(color: context.appText),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.phoneNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: context.appMuted,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isConnected ? _formatDuration(_durationSeconds) : _callStatusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: _isConnected ? AppColors.successGreen : AppColors.amber,
                  ),
                ),
                if (_isConnected) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, _) {
                          final h = _isMuted
                              ? 4.0
                              : 6.0 + 14.0 * sin((_waveController.value * 2 * pi) + (index * 0.8)).abs();
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: 3.5,
                            height: h,
                            decoration: BoxDecoration(
                              color: _isMuted ? context.appMuted : AppColors.successGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
                if (_showKeypad) ...[
                  const SizedBox(height: 20),
                  _buildInCallKeypad(),
                ],
                const Spacer(flex: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallControl(
                      icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: _isMuted ? 'Muted' : 'Mute',
                      isActive: _isMuted,
                      activeColor: AppColors.errorRed,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isMuted = !_isMuted);
                        VoiceCallAudioService.instance.setMuted(_isMuted);
                      },
                    ),
                    _buildCallControl(
                      icon: Icons.dialpad_rounded,
                      label: 'Keypad',
                      isActive: _showKeypad,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _showKeypad = !_showKeypad);
                      },
                    ),
                    _buildCallControl(
                      icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      label: _isSpeaker ? 'Speaker' : 'Earpiece',
                      isActive: _isSpeaker,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isSpeaker = !_isSpeaker);
                        VoiceCallAudioService.instance.setSpeaker(_isSpeaker);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                GestureDetector(
                  onTap: () => _endCall(),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66FF5A5A),
                          blurRadius: 22,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 34),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'End call',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInCallKeypad() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appLine),
      ),
      child: Column(
        children: [
          if (_keypadInput.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _keypadInput,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'].map((k) {
              return InkWell(
                onTap: () {
                  try {
                    CallAudioService.instance.playDialpadTone(k);
                  } catch (_) {}
                  setState(() => _keypadInput += k);
                },
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 52,
                  height: 40,
                  child: Center(
                    child: Text(
                      k,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.appText,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControl({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final bg = isActive ? (activeColor ?? AppColors.accent) : context.appSurface2;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : context.appText,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class IncomingCallDialog extends StatefulWidget {
  final CallSignal invite;
  final String accountId;
  final ChatRepository chatRepository;
  final String myNumber;
  final String myName;

  const IncomingCallDialog({
    super.key,
    required this.invite,
    required this.accountId,
    required this.chatRepository,
    required this.myNumber,
    required this.myName,
  });

  static _IncomingCallDialogState? _activeIncomingState;

  static void answerActiveCall() {
    _activeIncomingState?._acceptCall();
  }

  static void declineActiveCall() {
    _activeIncomingState?._declineCall();
  }

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  ChatContact? _matchedContact;
  StreamSubscription<CallSignal>? _incomingSignalSub;
  bool _handled = false;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    IncomingCallDialog._activeIncomingState = this;
    PhoneCallDialog.isCallActive = true;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    CallAudioService.instance.startRingtone();

    LocalNotificationService.showIncomingCallNotification(
      callerName: widget.invite.callerName,
      callerNumber: widget.invite.callerNumber,
      callId: widget.invite.callId,
    );

    _lookupContact();

    _incomingSignalSub = ChatSocketService().onCallSignal.listen((signal) {
      if (!mounted) return;
      if (signal.type == CallSignalType.end) {
        final caller10 = ChatSocketService.normalize10(widget.invite.callerNumber);
        final signalCaller10 = ChatSocketService.normalize10(signal.callerNumber);
        final signalSender10 = ChatSocketService.normalize10(signal.senderNumber);
        if (signal.callId == widget.invite.callId ||
            (caller10.isNotEmpty && (signalCaller10 == caller10 || signalSender10 == caller10))) {
          _onCallerEnded();
        }
      }
    });
  }

  void _onCallerEnded() {
    if (_handled) return;
    _handled = true;
    CallAudioService.instance.stopRingtone();
    LocalNotificationService.cancelCallNotification();
    widget.chatRepository.addCallLog(
      widget.accountId,
      CallLogItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contactKey: widget.invite.callerNumber,
        nickname: _matchedContact?.nickname ?? widget.invite.callerName,
        type: 'missed',
        durationSeconds: 0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _lookupContact() async {
    final contact = await widget.chatRepository.getContact(widget.accountId, widget.invite.callerNumber);
    if (contact != null && mounted) {
      setState(() {
        _matchedContact = contact;
      });
    }
  }

  @override
  void dispose() {
    if (IncomingCallDialog._activeIncomingState == this) {
      IncomingCallDialog._activeIncomingState = null;
    }
    _incomingSignalSub?.cancel();
    CallAudioService.instance.stopRingtone();
    LocalNotificationService.cancelCallNotification();
    _pulseController.dispose();
    if (!_accepted) {
      PhoneCallDialog.isCallActive = false;
    }
    super.dispose();
  }

  void _declineCall() {
    if (_handled) return;
    _handled = true;
    CallAudioService.instance.stopRingtone();
    CallAudioService.instance.playBusySignal();
    LocalNotificationService.cancelCallNotification();

    final myClean = widget.myNumber.isNotEmpty ? widget.myNumber : 'me';
    ChatSocketService().sendCallSignal(
      CallSignal(
        type: CallSignalType.end,
        callId: widget.invite.callId,
        callerNumber: widget.invite.callerNumber,
        callerName: widget.invite.callerName,
        calleeNumber: myClean,
        senderNumber: myClean,
        targetNumber: widget.invite.callerNumber,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        reason: 'declined',
      ),
    );

    widget.chatRepository.addCallLog(
      widget.accountId,
      CallLogItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contactKey: widget.invite.callerNumber,
        nickname: _matchedContact?.nickname ?? widget.invite.callerName,
        type: 'missed',
        durationSeconds: 0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    Navigator.of(context, rootNavigator: true).pop();
  }

  void _acceptCall() {
    if (_handled) return;
    _handled = true;
    _accepted = true;
    CallAudioService.instance.stopRingtone();
    LocalNotificationService.cancelCallNotification();

    final myClean = widget.myNumber.isNotEmpty ? widget.myNumber : 'me';

    ChatSocketService().sendCallSignal(
      CallSignal(
        type: CallSignalType.answer,
        callId: widget.invite.callId,
        callerNumber: widget.invite.callerNumber,
        callerName: widget.invite.callerName,
        calleeNumber: myClean,
        senderNumber: myClean,
        targetNumber: widget.invite.callerNumber,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    PhoneCallDialog.isCallActive = true;
    Navigator.of(context, rootNavigator: true).pushReplacement(
      _callRoute(
        PhoneCallDialog(
          phoneNumber: widget.invite.callerNumber,
          contactName: _matchedContact?.nickname ?? widget.invite.callerName,
          accountId: widget.accountId,
          chatRepository: widget.chatRepository,
          isIncoming: true,
          callId: widget.invite.callId,
          myNumber: widget.myNumber,
          myName: widget.myName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const avatarColors = [
      Color(0xFFE57373),
      Color(0xFF81C784),
      Color(0xFF64B5F6),
      Color(0xFFFFB74D),
      Color(0xFFBA68C8),
      Color(0xFF4DB6AC),
    ];
    final color = avatarColors[(_matchedContact?.avatarColor ?? 2) % avatarColors.length];

    final displayName = _matchedContact?.nickname ??
        (widget.invite.callerName.isNotEmpty ? widget.invite.callerName : widget.invite.callerNumber);
    final initial = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '#';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _declineCall();
      },
      child: Scaffold(
        backgroundColor: context.appBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.phoneIncoming, size: 14, color: AppColors.accent),
                      SizedBox(width: 6),
                      Text(
                        'Incoming Call...',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.22),
                      border: Border.all(color: color, width: 2.5),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: context.appText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  displayName,
                  style: AppTypography.h2.copyWith(color: context.appText),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.invite.callerNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: context.appMuted,
                    letterSpacing: 1.6,
                  ),
                ),
                const Spacer(flex: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIncomingAction(
                      label: 'Decline',
                      color: AppColors.errorRed,
                      icon: Icons.call_end_rounded,
                      onTap: _declineCall,
                    ),
                    _buildIncomingAction(
                      label: 'Accept',
                      color: AppColors.successGreen,
                      icon: Icons.call_rounded,
                      onTap: _acceptCall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingAction({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.38),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
