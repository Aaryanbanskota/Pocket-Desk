import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:pocketdesk/core/logging/app_logger.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/dashboard/presentation/widgets/app_hamburger_drawer.dart';
import 'package:pocketdesk/features/posts/data/models/instant_model.dart';
import 'package:pocketdesk/features/posts/data/models/post_model.dart';
import 'package:pocketdesk/features/posts/presentation/providers/posts_notifier.dart';

class PostsPage extends ConsumerStatefulWidget {
  const PostsPage({super.key});

  @override
  ConsumerState<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<PostsPage> {
  final _contentCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  final List<String> _selectedImagePaths = [];
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() => _isFabVisible = false);
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() => _isFabVisible = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _contentCtrl.dispose();
    _titleCtrl.dispose();
    _tagsCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<List<String>> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'],
      allowMultiple: true,
    );

    final paths = <String>[];
    if (result != null && result.paths.isNotEmpty) {
      for (final p in result.paths) {
        if (p != null) {
          paths.add(p);
          if (!_selectedImagePaths.contains(p)) {
            _selectedImagePaths.add(p);
          }
        }
      }
      setState(() {});
    }
    return paths;
  }

  Future<void> _addAudioAttachment(TextEditingController controller) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final filename = path.split(Platform.pathSeparator).last;
      final text = controller.text;
      final newText = text.isEmpty
          ? '🎙️ [Audio Note: $filename]'
          : '$text\n🎙️ [Audio Note: $filename]';
      controller.text = newText;
    } else {
      if (!mounted) return;
      final ctrl = TextEditingController();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mic_rounded, color: Color(0xFF8B95F6)),
              SizedBox(width: 8),
              Text('Voice Note / Audio'),
            ],
          ),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Enter audio description or voice note text...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final note = ctrl.text.trim();
                if (note.isNotEmpty) {
                  final text = controller.text;
                  controller.text = text.isEmpty
                      ? '🎙️ [Voice Note: $note]'
                      : '$text\n🎙️ [Voice Note: $note]';
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add Note'),
            ),
          ],
        ),
      );
      ctrl.dispose();
    }
  }

  Future<void> _addGifAttachment(TextEditingController controller) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gif'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      if (!_selectedImagePaths.contains(path)) {
        setState(() => _selectedImagePaths.add(path));
      }
      final text = controller.text;
      final filename = path.split(Platform.pathSeparator).last;
      controller.text =
          text.isEmpty ? '[GIF: $filename]' : '$text\n[GIF: $filename]';
    } else {
      if (!mounted) return;
      final ctrl = TextEditingController(
          text: 'https://media.giphy.com/media/express/giphy.gif');
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.gif_box_rounded, color: Color(0xFF8B95F6)),
              SizedBox(width: 8),
              Text('Add GIF Link'),
            ],
          ),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Enter GIF URL...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final url = ctrl.text.trim();
                if (url.isNotEmpty) {
                  final text = controller.text;
                  controller.text =
                      text.isEmpty ? 'GIF: $url' : '$text\nGIF: $url';
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add GIF'),
            ),
          ],
        ),
      );
      ctrl.dispose();
    }
  }

  Future<void> _addTodoList(TextEditingController controller) async {
    final item1Ctrl = TextEditingController();
    final item2Ctrl = TextEditingController();
    final item3Ctrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.checklist_rounded, color: Color(0xFF8B95F6)),
            SizedBox(width: 8),
            Text('Create To-Do List'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: item1Ctrl,
              decoration: const InputDecoration(
                hintText: 'Task 1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: item2Ctrl,
              decoration: const InputDecoration(
                hintText: 'Task 2 (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: item3Ctrl,
              decoration: const InputDecoration(
                hintText: 'Task 3 (optional)',
                border: OutlineInputBorder(),
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
            onPressed: () {
              final items = [
                item1Ctrl.text.trim(),
                item2Ctrl.text.trim(),
                item3Ctrl.text.trim(),
              ].where((s) => s.isNotEmpty).toList();
              if (items.isNotEmpty) {
                final listStr = items.map((i) => '- [ ] $i').join('\n');
                final text = controller.text;
                controller.text = text.isEmpty ? listStr : '$text\n\n$listStr';
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add List'),
          ),
        ],
      ),
    );
    item1Ctrl.dispose();
    item2Ctrl.dispose();
    item3Ctrl.dispose();
  }

  Widget _buildPostContentWithAudio(
      BuildContext context, String content, ColorScheme colorScheme) {
    final voiceNoteRegExp =
        RegExp(r'(?:🎙️ Voice Note:|\[Audio Note:)\s*([^\n\]]+)\]?');
    final match = voiceNoteRegExp.firstMatch(content);

    if (match != null) {
      final audioPath = match.group(1)?.trim() ?? '';
      final textWithoutAudio = content.replaceAll(voiceNoteRegExp, '').trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (textWithoutAudio.isNotEmpty)
            Text(
              textWithoutAudio,
              style:
                  TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          if (audioPath.isNotEmpty && File(audioPath).existsSync()) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _openVoicePlayingModal(context, audioPath),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: VoicePlayingIconWidget(size: 28, color: Color(0xFF8B95F6)),
              ),
            ),
          ],
        ],
      );
    }

    return Text(
      content,
      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile Editor Modal
  // ---------------------------------------------------------------------------

  void _showEditProfileModal() {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;

    final nameCtrl = TextEditingController(
        text: auth.user.displayName ?? auth.user.username);
    String? currentAvatar = auth.user.avatarBase64;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Profile',
                  style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final result =
                      await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.single.path != null) {
                    final bytes =
                        await File(result.files.single.path!).readAsBytes();
                    final b64 = base64Encode(bytes);
                    setModalState(() => currentAvatar = b64);
                  }
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      backgroundImage: currentAvatar != null
                          ? MemoryImage(base64Decode(currentAvatar!))
                          : null,
                      child: currentAvatar == null
                          ? Icon(Icons.person_rounded,
                              size: 40, color: colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Color(0xFF6C5CE7), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.outline)),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).updateProfile(
                        displayName: nameCtrl.text.trim(),
                        avatarBase64: currentAvatar,
                      );
                  if (context.mounted) Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Save Profile', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Instants Dashboard
  // ---------------------------------------------------------------------------

  void _openInstantsDashboard(List<InstantModel> instants) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _InstantsDashboardModal(
        instants: instants,
        onAddClick: () => _openCreateInstantCamera(),
        onDeleteClick: (id) => ref.read(instantsProvider.notifier).deleteInstant(id),
      ),
    );
  }

  void _openCreateInstantCamera({
    String? initialPath,
    String title = 'New Instant',
    ValueChanged<String>? onPhotoCaptured,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => _InstantCameraModal(
        initialPath: initialPath,
        title: title,
        onInstantCreated: (imagePath, textOverlay, textX, textY) async {
          if (imagePath.isNotEmpty) {
            if (onPhotoCaptured != null) {
              onPhotoCaptured(imagePath);
            } else {
              await ref.read(instantsProvider.notifier).createInstant(
                    imagePath: imagePath,
                    textOverlay: textOverlay,
                    textX: textX,
                    textY: textY,
                  );
            }
          }
        },
      ),
    );
  }

  Future<String> _fetchLocationTag() async {
    // 1. Try IP Geolocation first for real city/region/country (works on laptops & desktops without native GPS hardware)
    try {
      final res = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final city = data['city'] ?? '';
          final region = data['regionName'] ?? '';
          final country = data['country'] ?? '';
          final parts = [city, region, country]
              .where((s) => s.toString().trim().isNotEmpty)
              .toList();
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }
    } catch (_) {}

    // 2. Fallback to Geolocator (hardware GPS for mobile devices)
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Location Services Disabled';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Location Permission Denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Location Permission Blocked';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return '${position.latitude.toStringAsFixed(2)}°, ${position.longitude.toStringAsFixed(2)}°';
    } catch (e) {
      return 'Location Unavailable';
    }
  }

  Future<void> _showAudioRecorderModal(TextEditingController controller) async {
    AudioRecorder? recorder;
    Process? processRecorder;
    bool isRecording = false;
    int secondsRecorded = 0;
    Timer? timer;
    String? recordedFilePath;
    String? errorMessage;

    try {
      recorder = AudioRecorder();
      final hasPerm = await recorder.hasPermission();
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
        return;
      }
    } catch (e) {
      AppLogger.w('Permission check exception: $e');
      recorder = null;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mic_rounded, color: Color(0xFF8B95F6)),
              SizedBox(width: 8),
              Text('Record Voice Note'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '00:${secondsRecorded.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  if (isRecording) {
                    timer?.cancel();
                    try {
                      if (processRecorder != null) {
                        processRecorder!.kill(ProcessSignal.sigint);
                        processRecorder = null;
                      } else {
                        recordedFilePath = await recorder?.stop();
                      }
                    } catch (e) {
                      AppLogger.w('Error stopping recorder: $e');
                    }
                    setDialogState(() => isRecording = false);
                  } else {
                    final dir = await getApplicationDocumentsDirectory();
                    final timeStamp = DateTime.now().millisecondsSinceEpoch;
                    bool started = false;

                    // Try package:record first
                    try {
                      final path = '${dir.path}/voice_note_$timeStamp.m4a';
                      await recorder?.start(
                        const RecordConfig(encoder: AudioEncoder.aacLc),
                        path: path,
                      );
                      recordedFilePath = path;
                      started = true;
                    } catch (e) {
                      AppLogger.w('package:record failed, attempting linux system arecord/ffmpeg: $e');
                    }

                    // Fallback to Linux desktop system audio tools (pw-record / ffmpeg / arecord)
                    if (!started) {
                      try {
                        final path = '${dir.path}/voice_note_$timeStamp.wav';
                        try {
                          processRecorder = await Process.start('pw-record', [path]);
                        } catch (_) {
                          try {
                            processRecorder = await Process.start('ffmpeg', ['-y', '-f', 'pulse', '-i', 'default', path]);
                          } catch (_) {
                            processRecorder = await Process.start('arecord', ['-f', 'cd', path]);
                          }
                        }
                        recordedFilePath = path;
                        started = true;
                      } catch (err) {
                        AppLogger.e('Linux process recording error: $err');
                      }
                    }

                    if (started) {
                      setDialogState(() {
                        isRecording = true;
                        secondsRecorded = 0;
                        errorMessage = null;
                      });
                      timer = Timer.periodic(const Duration(seconds: 1), (t) {
                        setDialogState(() => secondsRecorded++);
                      });
                    } else {
                      setDialogState(() {
                        errorMessage =
                            'Microphone recording unavailable. Pick an audio file instead below!';
                      });
                    }
                  }
                },
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      isRecording ? Colors.redAccent : const Color(0xFF8B95F6),
                  child: Icon(
                    isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isRecording
                    ? 'Recording... Tap to stop'
                    : (recordedFilePath != null && File(recordedFilePath!).existsSync()
                        ? 'Recorded/Selected! Tap attach to add.'
                        : 'Tap mic to record or pick audio below'),
                style: TextStyle(
                  color: isRecording ? Colors.redAccent : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final res = await FilePicker.platform.pickFiles(type: FileType.audio);
                  if (res != null && res.files.single.path != null) {
                    recordedFilePath = res.files.single.path;
                    setDialogState(() {
                      errorMessage = null;
                    });
                  }
                },
                icon: const Icon(Icons.audio_file_rounded, size: 18),
                label: const Text('Pick Audio File'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                timer?.cancel();
                if (isRecording) {
                  try {
                    processRecorder?.kill(ProcessSignal.sigint);
                    await recorder?.stop();
                  } catch (_) {}
                }
                await recorder?.dispose();
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                timer?.cancel();
                if (isRecording) {
                  try {
                    processRecorder?.kill(ProcessSignal.sigint);
                    recordedFilePath ??= await recorder?.stop();
                  } catch (_) {}
                }
                await recorder?.dispose();

                if (recordedFilePath != null &&
                    recordedFilePath!.isNotEmpty &&
                    File(recordedFilePath!).existsSync()) {
                  final text = controller.text;
                  final voiceTag = '🎙️ Voice Note: $recordedFilePath';
                  controller.text =
                      text.isEmpty ? voiceTag : '$text\n$voiceTag';
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Attach Voice Note'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NEW POST SHEET
  // ---------------------------------------------------------------------------

  void _showCreatePostModal() {
    _contentCtrl.clear();
    _titleCtrl.clear();
    _tagsCtrl.clear();
    _selectedImagePaths.clear();

    bool isAiExcluded = false;
    String? selectedLocationTag;

    final auth = ref.read(authNotifierProvider).valueOrNull;
    final currentUser = auth is AuthAuthenticated ? auth.user : null;
    final avatarB64 = currentUser?.avatarBase64;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final bottomInsets = MediaQuery.of(modalContext).viewInsets.bottom;
          return Container(
            height: MediaQuery.of(modalContext).size.height * 0.90,
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInsets + 12),
            child: Column(
              children: [
                // Top Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: colorScheme.onSurface, size: 28),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B95F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                      ),
                      onPressed: () {
                        final rawText = _contentCtrl.text.trim();
                        if (rawText.isEmpty && _selectedImagePaths.isEmpty) return;

                        String? title;
                        String content = rawText;

                        if (rawText.contains('\n')) {
                          final lines = rawText.split('\n');
                          title = lines.first.trim();
                          content = lines.sublist(1).join('\n').trim();
                          if (content.isEmpty) {
                            content = title;
                          }
                        } else if (rawText.isNotEmpty) {
                          title = rawText;
                          content = rawText;
                        }

                        // Auto-extract #hashtags
                        final tagMatches = RegExp(r'#(\w+)').allMatches(rawText);
                        final tags = tagMatches.map((m) => m.group(1)!).toList();

                        ref.read(postsNotifierProvider.notifier).createPost(
                              content: content,
                              title: title,
                              imagePaths: List.from(_selectedImagePaths),
                              tags: tags,
                              isAiExcluded: isAiExcluded,
                              locationTag: selectedLocationTag,
                            );

                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'POST',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Content Field Area (Twitter / X Continuous Seamless Input)
                Expanded(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _showEditProfileModal,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            backgroundImage: avatarB64 != null
                                ? MemoryImage(base64Decode(avatarB64))
                                : null,
                            child: avatarB64 == null
                                ? Icon(Icons.person_rounded,
                                    color: colorScheme.onSurfaceVariant)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _contentCtrl,
                                maxLines: null,
                                autofocus: true,
                                style: TextStyle(
                                    color: colorScheme.onSurface, fontSize: 18),
                                decoration: InputDecoration(
                                  hintText: "What's happening?",
                                  hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                              if (selectedLocationTag != null) ...[
                                const SizedBox(height: 8),
                                Chip(
                                  avatar: const Icon(Icons.location_on_rounded,
                                      size: 16, color: Color(0xFF8B95F6)),
                                  label: Text(
                                    selectedLocationTag!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  deleteIcon: const Icon(Icons.close_rounded,
                                      size: 14),
                                  onDeleted: () {
                                    setModalState(() => selectedLocationTag = null);
                                  },
                                ),
                              ],
                              if (_selectedImagePaths.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedImagePaths.length,
                                    itemBuilder: (c, i) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.file(
                                              File(_selectedImagePaths[i]),
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                                      Container(
                                                width: 120,
                                                height: 120,
                                                color: colorScheme
                                                    .surfaceContainerHighest,
                                                child: Icon(
                                                    Icons.broken_image_rounded,
                                                    color: colorScheme
                                                        .onSurfaceVariant),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () {
                                                setModalState(() {
                                                  _selectedImagePaths
                                                      .removeAt(i);
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black87,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                    Icons.close_rounded,
                                                    size: 14,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Bar (Privacy Badge Toggle + Attachment Toolbar)
                Column(
                  children: [
                    Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        onTap: () {
                          setModalState(() => isAiExcluded = !isAiExcluded);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAiExcluded ? Icons.lock_rounded : Icons.smart_toy_rounded,
                                size: 16,
                                color: isAiExcluded ? colorScheme.onSurfaceVariant : const Color(0xFF8B95F6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAiExcluded ? '🙈 AI cannot view this post' : '🤖 AI can view this post',
                                style: TextStyle(
                                  color: isAiExcluded ? colorScheme.onSurfaceVariant : const Color(0xFF8B95F6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image_outlined,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add Gallery Photo',
                          onPressed: () async {
                            await _pickMedia();
                            setModalState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Take Photo',
                          onPressed: () {
                            _openCreateInstantCamera(
                              title: 'Post Photo',
                              onPhotoCaptured: (path) {
                                if (path.isNotEmpty) {
                                  setModalState(() {
                                    if (!_selectedImagePaths.contains(path)) {
                                      _selectedImagePaths.add(path);
                                    }
                                  });
                                  if (mounted) setState(() {});
                                }
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic_none_rounded,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Record Voice Audio',
                          onPressed: () async {
                            await _showAudioRecorderModal(_contentCtrl);
                            setModalState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.gif_box_outlined,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add GIF',
                          onPressed: () async {
                            await _addGifAttachment(_contentCtrl);
                            setModalState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_list_bulleted_rounded,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add List / To-Do',
                          onPressed: () {
                            final text = _contentCtrl.text;
                            final listPrefix = text.isEmpty || text.endsWith('\n') ? '- [ ] ' : '\n- [ ] ';
                            _contentCtrl.text = '$text$listPrefix';
                            setModalState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.location_on_outlined,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add Location Tag',
                          onPressed: () async {
                            final tag = await _fetchLocationTag();
                            setModalState(() => selectedLocationTag = tag);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMMENT COMPOSITION & REPLY SHEET
  // ---------------------------------------------------------------------------

  void _showCommentComposerSheet(PostModel post) {
    _commentCtrl.clear();
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final currentUser = auth is AuthAuthenticated ? auth.user : null;
    final avatarB64 = currentUser?.avatarBase64;
    final authorName = currentUser?.displayName ?? currentUser?.username ?? 'User';

    final hasImage = post.imagePaths.isNotEmpty && File(post.imagePaths.first).existsSync();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final bottomInsets = MediaQuery.of(modalContext).viewInsets.bottom;
          return Container(
            height: MediaQuery.of(modalContext).size.height * 0.90,
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInsets + 12),
            child: Column(
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: colorScheme.onSurface, size: 28),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B95F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                      ),
                      onPressed: () async {
                        final text = _commentCtrl.text.trim();
                        if (text.isNotEmpty) {
                          await ref
                              .read(postsNotifierProvider.notifier)
                              .addComment(post, text);
                          _commentCtrl.clear();
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: const Text(
                        'POST',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Parent Post Snippet & Thread Connector
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: colorScheme.surfaceContainerHighest,
                                    child: Icon(Icons.person_rounded,
                                        color: colorScheme.onSurfaceVariant, size: 20),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: colorScheme.outline.withValues(alpha: 0.3),
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authorName,
                                      style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    if (post.title != null && post.title!.isNotEmpty)
                                      Text(
                                        post.title!,
                                        style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                    if (post.content.isNotEmpty)
                                      Text(
                                        post.content,
                                        style: TextStyle(
                                            color: colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.8),
                                            fontSize: 12),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (hasImage)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(post.imagePaths.first),
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Commenter Input Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              backgroundImage: avatarB64 != null
                                  ? MemoryImage(base64Decode(avatarB64))
                                  : null,
                              child: avatarB64 == null
                                  ? Icon(Icons.person_rounded,
                                      color: colorScheme.onSurfaceVariant)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _commentCtrl,
                                maxLines: null,
                                style: TextStyle(
                                    color: colorScheme.onSurface, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Comment something |',
                                  hintStyle: TextStyle(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                      fontSize: 16),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Footer Bar with Audio, GIF & List icons
                Column(
                  children: [
                    Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.public_rounded,
                              size: 16, color: Color(0xFF8B95F6)),
                          SizedBox(width: 6),
                          Text(
                            'AI can view this post',
                            style: TextStyle(
                              color: Color(0xFF8B95F6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.mic_none_rounded,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Record Voice Audio',
                          onPressed: () => _addAudioAttachment(_commentCtrl),
                        ),
                        IconButton(
                          icon: const Icon(Icons.gif_box_outlined,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add GIF',
                          onPressed: () => _addGifAttachment(_commentCtrl),
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_list_bulleted_rounded,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add To-Do / List',
                          onPressed: () => _addTodoList(_commentCtrl),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SINGLE POST DETAILED VIEW
  // ---------------------------------------------------------------------------

  void _openPostDetailView(PostModel post) {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final currentUser = auth is AuthAuthenticated ? auth.user : null;
    final authorName = currentUser?.displayName ?? currentUser?.username ?? 'User';
    final avatarB64 = currentUser?.avatarBase64;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final postsState = ref.watch(postsNotifierProvider).valueOrNull ?? [];
          final currentPost =
              postsState.firstWhere((p) => p.id == post.id, orElse: () => post);
          final hasImage = currentPost.imagePaths.isNotEmpty &&
              File(currentPost.imagePaths.first).existsSync();

          return Container(
            height: MediaQuery.of(context).size.height * 0.92,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Close Bar
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: colorScheme.onSurface, size: 28),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(width: 8),
                    Text('Post Detail',
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView(
                    children: [
                      // Author Row
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          backgroundImage: avatarB64 != null
                              ? MemoryImage(base64Decode(avatarB64))
                              : null,
                          child: avatarB64 == null
                              ? Icon(Icons.person_rounded,
                                  color: colorScheme.onSurfaceVariant)
                              : null,
                        ),
                        title: Text(authorName,
                            style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold)),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              color: colorScheme.onSurfaceVariant),
                          onSelected: (val) {
                            final notifier =
                                ref.read(postsNotifierProvider.notifier);
                            if (val == 'pin') {
                              notifier.togglePin(currentPost);
                            }
                            if (val == 'delete') {
                              notifier.deletePost(currentPost.id);
                              Navigator.pop(ctx);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(currentPost.isPinned ? 'Unpin' : 'Pin'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),

                      // Title & Content
                      if (currentPost.title != null && currentPost.title!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            currentPost.title!,
                            style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (currentPost.content.isNotEmpty)
                        Text(
                          currentPost.content,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant, fontSize: 14),
                        ),
                      const SizedBox(height: 12),

                      // Attached Media Container
                      if (hasImage)
                        SwipeablePostImageGallery(
                          imagePaths: currentPost.imagePaths,
                          height: 260,
                        ),
                      const SizedBox(height: 12),

                      // Date & Total Comment Timestamp Bar
                      Text(
                        '${currentPost.createdAt.hour}:${currentPost.createdAt.minute.toString().padLeft(2, '0')} • ${currentPost.comments.length} comments',
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontSize: 12),
                      ),
                      Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 20),

                      // Action Bar (Like, Comment, Bookmark)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              currentPost.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: currentPost.isLiked
                                  ? Colors.red
                                  : colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => ref
                                .read(postsNotifierProvider.notifier)
                                .toggleLike(currentPost),
                          ),
                          IconButton(
                            icon: Icon(Icons.chat_bubble_outline_rounded,
                                color: colorScheme.onSurfaceVariant),
                            onPressed: () => _showCommentComposerSheet(currentPost),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              currentPost.isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: currentPost.isSaved
                                  ? const Color(0xFF8B95F6)
                                  : colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => ref
                                .read(postsNotifierProvider.notifier)
                                .toggleSave(currentPost),
                          ),
                        ],
                      ),
                      Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 20),

                      Text(
                        'Comments',
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // List of Comments
                      if (currentPost.comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No comments yet.',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.6)),
                            ),
                          ),
                        )
                      else
                        ...List.generate(currentPost.comments.length, (i) {
                          final author = currentPost.commentAuthors[i];
                          final comment = currentPost.comments[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.person_rounded,
                                      size: 16, color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(author,
                                          style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text(comment,
                                          style: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN FEED BUILDER
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final currentUser = auth is AuthAuthenticated ? auth.user : null;
    final authorName = currentUser?.displayName ?? currentUser?.username ?? 'User';

    final postsAsync = ref.watch(postsNotifierProvider);
    final instantsAsync = ref.watch(instantsProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      drawer: const AppHamburgerDrawer(),
      appBar: AppBar(
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded,
                color: colorScheme.onSurface, size: 26),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open Menu',
          ),
        ),
        title: Text(
          'Personal Feed',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_a_photo_outlined,
                color: colorScheme.onSurface, size: 22),
            onPressed: () => _openCreateInstantCamera(),
            tooltip: 'Camera / Instant',
          ),
          IconButton(
            icon: Icon(Icons.add_rounded,
                color: colorScheme.onSurface, size: 28),
            onPressed: _showCreatePostModal,
            tooltip: 'Create New Post',
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Instants Header Row
          SliverToBoxAdapter(
            child: Container(
              height: 95,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: instantsAsync.when(
                data: (instants) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    GestureDetector(
                      onTap: _openCreateInstantCamera,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF8B95F6), width: 2),
                              color: colorScheme.surfaceContainerHighest,
                            ),
                            child: const Icon(Icons.add_a_photo_rounded,
                                color: Color(0xFF8B95F6), size: 24),
                          ),
                          const SizedBox(height: 4),
                          Text('Insta story',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    if (instants.isNotEmpty)
                      Builder(builder: (context) {
                        final firstPath = instants.first.imagePath;
                        final hasRingFile = firstPath.isNotEmpty &&
                            File(firstPath).existsSync();
                        return GestureDetector(
                          onTap: () => _openInstantsDashboard(instants),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.pinkAccent, width: 2.5),
                                  color: colorScheme.surfaceContainerHighest,
                                  image: hasRingFile
                                      ? DecorationImage(
                                          image: FileImage(File(firstPath)),
                                          fit: BoxFit.cover)
                                      : null,
                                ),
                                child: hasRingFile
                                    ? null
                                    : const Icon(Icons.star_rounded,
                                        color: Colors.pinkAccent),
                              ),
                              const SizedBox(height: 4),
                              Text('Your Instants',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface)),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),

          SliverToBoxAdapter(child: Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1)),

          // Feed Posts List
          postsAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B95F6)))),
            error: (e, _) => SliverFillRemaining(
                child: Center(
                    child: Text('Error: $e',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)))),
            data: (posts) {
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dynamic_feed_rounded,
                            size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('Your feed is empty.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B95F6),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _showCreatePostModal,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create First Post'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    final avatarB64 = currentUser?.avatarBase64;
                    final hasImage = post.imagePaths.isNotEmpty &&
                        File(post.imagePaths.first).existsSync();

                    return InkWell(
                      onTap: () => _openPostDetailView(post),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header User Row
                            ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                backgroundImage: avatarB64 != null
                                    ? MemoryImage(base64Decode(avatarB64))
                                    : null,
                                child: avatarB64 == null
                                    ? Icon(Icons.person_rounded,
                                        color: colorScheme.onSurfaceVariant)
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Text(authorName,
                                      style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.bold)),
                                  if (post.isAiExcluded) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('🙈 AI Excluded',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded,
                                    color: colorScheme.onSurfaceVariant),
                                onSelected: (val) {
                                  final notifier =
                                      ref.read(postsNotifierProvider.notifier);
                                  if (val == 'pin') {
                                    notifier.togglePin(post);
                                  }
                                  if (val == 'delete') {
                                    notifier.deletePost(post.id);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                      value: 'pin',
                                      child:
                                          Text(post.isPinned ? 'Unpin' : 'Pin')),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),

                            // Post Title & Content
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (post.title != null && post.title!.isNotEmpty)
                                    Text(
                                      post.title!,
                                      style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  if (post.content.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    _buildPostContentWithAudio(
                                        context, post.content, colorScheme),
                                  ],
                                  if (post.locationTag != null &&
                                      post.locationTag!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded,
                                            size: 13,
                                            color: Color(0xFF8B95F6)),
                                        const SizedBox(width: 4),
                                        Text(
                                          post.locationTag!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF8B95F6),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Media Box Container (Tap image explicitly opens post detail)
                            if (hasImage)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: SwipeablePostImageGallery(
                                  imagePaths: post.imagePaths,
                                  height: 240,
                                ),
                              ),

                            // Bottom Interaction Icons (Heart, Comment bubble, Bookmark)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      post.isLiked
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: post.isLiked
                                          ? Colors.red
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => ref
                                        .read(postsNotifierProvider.notifier)
                                        .toggleLike(post),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                        Icons.mode_comment_outlined,
                                        color: colorScheme.onSurfaceVariant),
                                    onPressed: () =>
                                        _showCommentComposerSheet(post),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(
                                      post.isSaved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      color: post.isSaved
                                          ? const Color(0xFF8B95F6)
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => ref
                                        .read(postsNotifierProvider.notifier)
                                        .toggleSave(post),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: posts.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isFabVisible ? 1.0 : 0.0,
        child: _isFabVisible
            ? FloatingActionButton(
                backgroundColor: const Color(0xFF8B95F6),
                onPressed: _showCreatePostModal,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              )
            : null,
      ),
    );
  }
}

class _InstantCameraModal extends StatefulWidget {
  const _InstantCameraModal({
    required this.onInstantCreated,
    this.initialPath,
    this.title = 'New Instant',
  });

  final String? initialPath;
  final String title;
  final Future<void> Function(
          String imagePath, String? textOverlay, double textX, double textY)
      onInstantCreated;

  @override
  State<_InstantCameraModal> createState() => _InstantCameraModalState();
}

class _InstantCameraModalState extends State<_InstantCameraModal> {
  final _textCtrl = TextEditingController();
  Offset _textOffset = const Offset(80, 250);
  String _imagePath = '';
  List<CameraDescription> _availableCameras = [];
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialPath ?? '';
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        await _setupController(_availableCameras[_selectedCameraIndex]);
      } else {
        if (mounted) {
          setState(() {
            _cameraError = 'No camera hardware available.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = e.toString();
        });
      }
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraError = 'Failed to start camera: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newMode);
      if (mounted) {
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (kIsWeb || Platform.isLinux) return;
    if (_availableCameras.length < 2) return;

    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _availableCameras.length;
    setState(() {
      _isCameraInitialized = false;
    });
    await _setupController(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> _captureOrPost() async {
    if (_isCapturing) return;

    String finalPath = _imagePath;
    final size = MediaQuery.of(context).size;

    if (finalPath.isEmpty) {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        setState(() => _isCapturing = true);
        try {
          final XFile photo = await _cameraController!.takePicture();
          finalPath = photo.path;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to capture photo: $e')),
            );
          }
          setState(() => _isCapturing = false);
          return;
        }
        setState(() => _isCapturing = false);
      } else {
        // When live camera stream is unavailable (e.g. laptop without camera), open photo picker directly
        final pickerResult =
            await FilePicker.platform.pickFiles(type: FileType.image);
        if (pickerResult != null && pickerResult.files.single.path != null) {
          finalPath = pickerResult.files.single.path!;
        } else {
          return;
        }
      }
    }

    final normX = (_textOffset.dx / size.width).clamp(0.0, 1.0);
    final normY = (_textOffset.dy / size.height).clamp(0.0, 1.0);

    await widget.onInstantCreated(
      finalPath,
      _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim(),
      normX,
      normY,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLinuxOrWeb = kIsWeb || Platform.isLinux;
    final canSwitchCamera = !isLinuxOrWeb && _availableCameras.length > 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.96,
      color: Colors.black,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  widget.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library_rounded,
                      color: Colors.white, size: 24),
                  tooltip: 'Choose from gallery',
                  onPressed: () async {
                    final pickerResult = await FilePicker.platform
                        .pickFiles(type: FileType.image);
                    if (pickerResult != null &&
                        pickerResult.files.single.path != null) {
                      setState(() {
                        _imagePath = pickerResult.files.single.path!;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(44),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_imagePath.isNotEmpty && File(_imagePath).existsSync())
                      Image.file(File(_imagePath), fit: BoxFit.cover)
                    else if (_isCameraInitialized && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else
                      Container(
                        color: const Color(0xFF1E293B),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white70, size: 54),
                              const SizedBox(height: 12),
                              Text(
                                _cameraError ?? 'Initializing Camera Stream…',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      left: _textOffset.dx,
                      top: _textOffset.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _textOffset += details.delta;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _textCtrl.text.isEmpty
                                ? 'Tap top bar to type overlay text'
                                : _textCtrl.text,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: TextField(
                        controller: _textCtrl,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Type overlay text…',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.black54,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _toggleFlash,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          _isFlashOn ? Colors.amber : const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFlashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color: _isFlashOn ? Colors.black : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _captureOrPost,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.6), width: 5),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _isCapturing ? Colors.amber : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                    strokeWidth: 3, color: Colors.black),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: canSwitchCamera ? _switchCamera : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: canSwitchCamera
                          ? const Color(0xFF1E293B)
                          : Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flip_camera_ios_rounded,
                      color: canSwitchCamera ? Colors.white : Colors.white38,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceNotePlayerWidget extends StatefulWidget {
  const VoiceNotePlayerWidget({super.key, required this.audioPath});

  final String audioPath;

  @override
  State<VoiceNotePlayerWidget> createState() => _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends State<VoiceNotePlayerWidget> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  Process? _sysPlayProcess;
  Timer? _playTimer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isLinux) {
      _player = null;
      return;
    }
    try {
      final player = AudioPlayer();
      _player = player;
      _durationSub = player.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      _positionSub = player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _playerStateSub = player.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() => _isPlaying = state == PlayerState.playing);
        }
      });
    } catch (e) {
      AppLogger.w('AudioPlayer plugin not available on this platform: $e');
      _player = null;
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    try {
      _player?.dispose();
    } catch (_) {}
    _sysPlayProcess?.kill();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      _playTimer?.cancel();
      if (_player != null) {
        try {
          await _player!.pause();
        } catch (_) {}
      }
      _sysPlayProcess?.kill();
      _sysPlayProcess = null;
      if (mounted) setState(() => _isPlaying = false);
    } else {
      if (!File(widget.audioPath).existsSync()) return;

      bool started = false;
      if (_player != null) {
        try {
          await _player!.play(DeviceFileSource(widget.audioPath));
          started = true;
        } catch (e) {
          AppLogger.w('AudioPlayer.play error, falling back to desktop system player: $e');
        }
      }

      if (!started) {
        try {
          try {
            _sysPlayProcess = await Process.start('pw-play', [widget.audioPath]);
          } catch (_) {
            try {
              _sysPlayProcess = await Process.start('ffplay', ['-nodisp', '-autoexit', widget.audioPath]);
            } catch (_) {
              _sysPlayProcess = await Process.start('aplay', [widget.audioPath]);
            }
          }
          started = true;
          _sysPlayProcess?.exitCode.then((_) {
            _playTimer?.cancel();
            if (mounted) {
              setState(() {
                _isPlaying = false;
                _position = Duration.zero;
              });
            }
          });
        } catch (err) {
          AppLogger.e('System player error: $err');
        }
      }

      if (started) {
        _playTimer?.cancel();
        setState(() {
          _isPlaying = true;
          _position = Duration.zero;
        });
        _playTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return;
          setState(() {
            _position += const Duration(seconds: 1);
          });
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final durationText = _duration > Duration.zero
        ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
        : _formatDuration(_position);

    final progressRatio = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : (_isPlaying ? ((_position.inSeconds % 10) / 10.0) : 0.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF8B95F6),
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mic_rounded, size: 12, color: Color(0xFF8B95F6)),
                    const SizedBox(width: 4),
                    Text(
                      'Voice note',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      durationText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 3,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B95F6)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SwipeablePostImageGallery extends StatefulWidget {
  const SwipeablePostImageGallery({
    super.key,
    required this.imagePaths,
    this.height = 240,
    this.borderRadius = 16,
  });

  final List<String> imagePaths;
  final double height;
  final double borderRadius;

  @override
  State<SwipeablePostImageGallery> createState() =>
      _SwipeablePostImageGalleryState();
}

class _SwipeablePostImageGalleryState
    extends State<SwipeablePostImageGallery> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validPaths = widget.imagePaths
        .where((p) => p.isNotEmpty && File(p).existsSync())
        .toList();

    if (validPaths.isEmpty) return const SizedBox.shrink();

    if (validPaths.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.file(
          File(validPaths.first),
          height: widget.height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: PageView.builder(
              controller: _pageController,
              itemCount: validPaths.length,
              onPageChanged: (idx) {
                setState(() => _currentPage = idx);
              },
              itemBuilder: (ctx, idx) {
                return Image.file(
                  File(validPaths[idx]),
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              },
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPage + 1}/${validPaths.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    validPaths.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == i ? 16 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == i
                            ? const Color(0xFF8B95F6)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Voice Playing Modal & Widgets
// -----------------------------------------------------------------------------

void _openVoicePlayingModal(BuildContext context, String audioPath) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => VoicePlayingModalContent(audioPath: audioPath),
  );
}

class VoicePlayingModalContent extends StatefulWidget {
  final String audioPath;

  const VoicePlayingModalContent({super.key, required this.audioPath});

  @override
  State<VoicePlayingModalContent> createState() =>
      _VoicePlayingModalContentState();
}

class _VoicePlayingModalContentState extends State<VoicePlayingModalContent> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;
  Process? _fallbackProcess;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    if (!File(widget.audioPath).existsSync()) return;

    if (!Platform.isAndroid && !Platform.isIOS) {
      try {
        final result = await Process.run('ffprobe', [
          '-v',
          'error',
          '-show_entries',
          'format=duration',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          widget.audioPath,
        ]);
        if (result.exitCode == 0) {
          final secs = double.tryParse(result.stdout.toString().trim());
          if (secs != null) {
            setState(() {
              _duration = Duration(milliseconds: (secs * 1000).toInt());
            });
          }
        }
      } catch (_) {}

      try {
        _fallbackProcess = await Process.start('pw-play', [widget.audioPath]);
      } catch (_) {
        try {
          _fallbackProcess = await Process.start('ffplay', ['-nodisp', '-autoexit', widget.audioPath]);
        } catch (_) {
          try {
            _fallbackProcess = await Process.start('aplay', [widget.audioPath]);
          } catch (_) {}
        }
      }

      if (_fallbackProcess != null) {
        setState(() => _isPlaying = true);
        final startTime = DateTime.now();
        _fallbackTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
          final elapsed = DateTime.now().difference(startTime);
          if (_duration > Duration.zero && elapsed >= _duration) {
            timer.cancel();
            setState(() {
              _position = _duration;
              _isPlaying = false;
            });
          } else {
            setState(() {
              _position = elapsed;
            });
          }
        });
        _fallbackProcess!.exitCode.then((_) {
          _fallbackTimer?.cancel();
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _position = _duration;
            });
          }
        });
        return;
      }
    }

    try {
      _player = AudioPlayer();
      await _player!.setSource(DeviceFileSource(widget.audioPath));

      _durSub = _player!.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });

      _posSub = _player!.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });

      _stateSub = _player!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() => _isPlaying = state == PlayerState.playing);
        }
      });

      await _player!.resume();
    } catch (_) {}
  }

  void _togglePlayPause() async {
    if (_fallbackProcess != null) {
      if (_isPlaying) {
        _fallbackProcess?.kill();
        _fallbackTimer?.cancel();
        setState(() => _isPlaying = false);
      } else {
        await _initAudioPlayer();
      }
      return;
    }

    if (_player == null) return;
    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.resume();
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _fallbackProcess?.kill();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Voice Playing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 32),
          const VoicePlayingIconWidget(size: 90, color: Color(0xFF8B95F6)),
          const SizedBox(height: 28),
          Text(
            _formatDuration(_position),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: const Color(0xFF8B95F6),
              inactiveTrackColor: const Color(0xFF8B95F6).withValues(alpha: 0.2),
              thumbColor: const Color(0xFF8B95F6),
              overlayColor: const Color(0xFF8B95F6).withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _duration.inMilliseconds > 0
                  ? _position.inMilliseconds
                      .clamp(0, _duration.inMilliseconds)
                      .toDouble()
                  : 0.0,
              max: _duration.inMilliseconds > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1.0,
              onChanged: (val) {
                if (_player != null) {
                  _player!.seek(Duration(milliseconds: val.toInt()));
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF8B95F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class VoicePlayingIconWidget extends StatelessWidget {
  final double size;
  final Color color;

  const VoicePlayingIconWidget({
    super.key,
    this.size = 24,
    this.color = const Color(0xFF8B95F6),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _VoicePlayingIconPainter(color: color),
    );
  }
}

class _VoicePlayingIconPainter extends CustomPainter {
  final Color color;

  _VoicePlayingIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    final headW = w * 0.28;
    final headH = h * 0.45;
    final headLeft = (w - headW) / 2;
    final headTop = h * 0.22;
    final headRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(headLeft, headTop, headW, headH),
      Radius.circular(headW / 2),
    );
    canvas.drawRRect(headRRect, paint);

    strokePaint.strokeWidth = w * 0.07;
    final standTop = headTop + headH * 0.35;
    final standBottom = headTop + headH + h * 0.08;
    final standRect = Rect.fromLTRB(
      headLeft - w * 0.08,
      standTop,
      headLeft + headW + w * 0.08,
      standBottom,
    );
    canvas.drawArc(standRect, 0, 3.14159, false, strokePaint);

    final stemTop = standBottom;
    final stemBottom = stemTop + h * 0.10;
    canvas.drawLine(
      Offset(w / 2, stemTop),
      Offset(w / 2, stemBottom),
      strokePaint,
    );

    final baseWidth = headW * 1.3;
    canvas.drawLine(
      Offset(w / 2 - baseWidth / 2, stemBottom),
      Offset(w / 2 + baseWidth / 2, stemBottom),
      strokePaint,
    );

    final barW = w * 0.055;
    final innerBarH = h * 0.30;
    final outerBarH = h * 0.18;
    final barYCenter = headTop + headH * 0.5;

    final innerLeftX = headLeft - w * 0.14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(innerLeftX - barW / 2, barYCenter - innerBarH / 2, barW, innerBarH),
        Radius.circular(barW / 2),
      ),
      paint,
    );

    final outerLeftX = innerLeftX - w * 0.11;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(outerLeftX - barW / 2, barYCenter - outerBarH / 2, barW, outerBarH),
        Radius.circular(barW / 2),
      ),
      paint,
    );

    final innerRightX = headLeft + headW + w * 0.14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(innerRightX - barW / 2, barYCenter - innerBarH / 2, barW, innerBarH),
        Radius.circular(barW / 2),
      ),
      paint,
    );

    final outerRightX = innerRightX + w * 0.11;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(outerRightX - barW / 2, barYCenter - outerBarH / 2, barW, outerBarH),
        Radius.circular(barW / 2),
      ),
      paint,
    );

    final dot1W = w * 0.07;
    final dot1H = h * 0.11;
    final dot1X = headLeft - w * 0.05;
    final dot1Y = headTop - h * 0.12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(dot1X - dot1W / 2, dot1Y - dot1H / 2, dot1W, dot1H),
        Radius.circular(dot1W / 2),
      ),
      paint,
    );

    final dot2Radius = w * 0.04;
    final dot2X = headLeft + headW + w * 0.06;
    final dot2Y = headTop - h * 0.10;
    canvas.drawCircle(Offset(dot2X, dot2Y), dot2Radius, paint);
  }

  @override
  bool shouldRepaint(covariant _VoicePlayingIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

// -----------------------------------------------------------------------------
// Instants Dashboard Story Viewer Modal
// -----------------------------------------------------------------------------

class _InstantsDashboardModal extends StatefulWidget {
  final List<InstantModel> instants;
  final VoidCallback onAddClick;
  final ValueChanged<int> onDeleteClick;

  const _InstantsDashboardModal({
    required this.instants,
    required this.onAddClick,
    required this.onDeleteClick,
  });

  @override
  State<_InstantsDashboardModal> createState() =>
      _InstantsDashboardModalState();
}

class _InstantsDashboardModalState extends State<_InstantsDashboardModal> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final instants = widget.instants;

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                if (instants.isNotEmpty) ...[
                  Row(
                    children: List.generate(
                      instants.length,
                      (idx) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: idx <= _currentIndex
                                ? const Color(0xFF8B95F6)
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Text(
                      instants.isNotEmpty
                          ? 'My Instants (${_currentIndex + 1}/${instants.length})'
                          : 'My Instants',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_a_photo_rounded,
                          color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onAddClick();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: instants.isEmpty
                ? const Center(
                    child: Text(
                      'No Instants yet. Tap camera to create!',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: instants.length,
                    onPageChanged: (idx) {
                      setState(() => _currentIndex = idx);
                    },
                    itemBuilder: (context, i) {
                      final inst = instants[i];
                      final hasFile = inst.imagePath.isNotEmpty &&
                          File(inst.imagePath).existsSync();

                      return GestureDetector(
                        onTapUp: (details) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final tapX = details.globalPosition.dx;

                          if (tapX < screenWidth * 0.35) {
                            // Tap left 35% -> previous instant
                            if (_currentIndex > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            }
                          } else {
                            // Tap right/center -> next instant or close if on last
                            if (_currentIndex < instants.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: hasFile
                                  ? Image.file(
                                      File(inst.imagePath),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: const Color(0xFF1E293B),
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image_rounded,
                                          color: Colors.white54,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                            ),
                            if (inst.textOverlay != null &&
                                inst.textOverlay!.isNotEmpty)
                              Positioned(
                                left: inst.textX *
                                    MediaQuery.of(context).size.width *
                                    0.8,
                                top: inst.textY *
                                    MediaQuery.of(context).size.height *
                                    0.6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    inst.textOverlay!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            if (_currentIndex > 0)
                              Positioned(
                                left: 12,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            if (_currentIndex < instants.length - 1)
                              Positioned(
                                right: 12,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete_forever_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Delete Instant',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogCtx) => AlertDialog(
                                        title: const Text('Delete Instant?'),
                                        content: const Text(
                                          'Are you sure you want to permanently delete this Instant?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogCtx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogCtx, true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      widget.onDeleteClick(inst.id);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


