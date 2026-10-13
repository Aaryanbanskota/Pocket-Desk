import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/widgets/app_bottom_sheet.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../../feed/data/feed_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../tasks/data/tasks_repository.dart';

class ProfileScreen extends StatefulWidget {
  final UserSession session;
  final AuthRepository authRepository;
  final TasksRepository tasksRepository;
  final NotesRepository notesRepository;
  final FeedRepository feedRepository;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final ValueChanged<UserSession> onSessionUpdated;
  final VoidCallback onLogout;
  final VoidCallback? onOpenSettings;

  const ProfileScreen({
    super.key,
    required this.session,
    required this.authRepository,
    required this.tasksRepository,
    required this.notesRepository,
    required this.feedRepository,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.onSessionUpdated,
    required this.onLogout,
    this.onOpenSettings,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserSession _currentSession;
  int _postsCount = 0;
  int _doneTasksCount = 0;
  int _dayStreak = 0;
  int _notesCount = 0;
  List<MyDayFeedPost> _mediaPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _loadStats();
  }

  Future<void> _loadStats() async {
    final accountId = _currentSession.accountId;

    final tasks = await widget.tasksRepository.getTasks(accountId);
    final notes = await widget.notesRepository.getNotes(accountId);
    final posts = await widget.feedRepository.getPosts(accountId);

    final doneTasks = tasks.where((t) => t.isDone).toList();

    // Calculate day streak based on completion dates
    final doneDates = doneTasks
        .where((t) => t.doneAt != null)
        .map((t) => DateTime.fromMillisecondsSinceEpoch(t.doneAt!).toIso8601String().substring(0, 10))
        .toSet();

    int streak = 0;
    var d = DateTime.now();
    final todayStr = d.toIso8601String().substring(0, 10);
    if (!doneDates.contains(todayStr)) {
      d = d.subtract(const Duration(days: 1));
    }
    while (doneDates.contains(d.toIso8601String().substring(0, 10))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }

    final media = posts.where((p) => p.imagePath.isNotEmpty).toList();

    if (mounted) {
      setState(() {
        _doneTasksCount = doneTasks.length;
        _notesCount = notes.length;
        _postsCount = posts.length;
        _dayStreak = streak;
        _mediaPosts = media;
        _isLoading = false;
      });
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _currentSession.name);
    final handleController = TextEditingController(text: _currentSession.handle);
    final bioController = TextEditingController(text: _currentSession.bio);
    String tempAvatarPath = _currentSession.avatarPath;
    String tempCoverPath = _currentSession.coverPath;
    final picker = ImagePicker();

    AppBottomSheet.show<void>(
      context: context,
      title: 'Edit Profile',
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          final isDark = Theme.of(modalContext).brightness == Brightness.dark;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
          final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
          final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar and Banner Pickers
                Row(
                  children: [
                    // Avatar Picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setModalState(() => tempAvatarPath = picked.path);
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: tempAvatarPath.isNotEmpty && File(tempAvatarPath).existsSync()
                                  ? Image.file(File(tempAvatarPath), fit: BoxFit.cover)
                                  : Center(
                                      child: Text(
                                        _currentSession.name.isNotEmpty
                                            ? _currentSession.name[0].toUpperCase()
                                            : 'U',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.camera, size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Cover Banner Picker
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await picker.pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            setModalState(() => tempCoverPath = picked.path);
                          }
                        },
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: tempCoverPath.isNotEmpty && File(tempCoverPath).existsSync()
                                ? Image.file(File(tempCoverPath), fit: BoxFit.cover)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.image, size: 18, color: textMuted),
                                      const SizedBox(width: 8),
                                      Text('Change banner', style: TextStyle(color: textMuted, fontSize: 13)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text('Name', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Username', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: handleController,
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    prefixText: '@',
                    prefixStyle: TextStyle(color: textMuted, fontSize: 15),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Bio', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Add a short bio...',
                    hintStyle: TextStyle(color: textMuted),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    if (newName.length < 2) return;
                    final newHandle = handleController.text.trim();
                    final newBio = bioController.text.trim();

                    final updated = await widget.authRepository.updateProfile(
                      currentSession: _currentSession,
                      newName: newName,
                      newHandle: newHandle,
                      newBio: newBio,
                      newAvatarPath: tempAvatarPath,
                      newCoverPath: tempCoverPath,
                    );

                    if (!mounted) return;
                    setState(() {
                      _currentSession = updated;
                    });
                    widget.onSessionUpdated(updated);
                    if (modalContext.mounted) {
                      Navigator.of(modalContext).pop();
                    }
                    if (mounted) {
                      UndoToast.show(context, message: 'Profile updated');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showConvertToCloudDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? errorMsg;
    String? successInfoMsg;
    bool isConverting = false;
    bool isCheckingConfirmation = false;
    bool isWaitingForConfirmation = false;
    bool isResending = false;
    int resendCooldownSeconds = 0;
    Timer? resendCooldownTimer;
    StreamSubscription<AuthState>? authSubscription;

    AppBottomSheet.show<void>(
      context: context,
      title: 'Convert to Cloud Account',
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          final isDark = Theme.of(modalContext).brightness == Brightness.dark;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
          final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
          final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

          void startResendCooldown([int seconds = 60]) {
            resendCooldownTimer?.cancel();
            setModalState(() => resendCooldownSeconds = seconds);
            resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (resendCooldownSeconds <= 1) {
                timer.cancel();
                setModalState(() => resendCooldownSeconds = 0);
              } else {
                setModalState(() => resendCooldownSeconds--);
              }
            });
          }

          if (isWaitingForConfirmation) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentOrange.withOpacity(0.35)),
                      ),
                      child: const Icon(LucideIcons.mailCheck, color: AppColors.accentOrange, size: 28),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Check your Gmail',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We sent a confirmation link to:\n${emailController.text.trim()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions:',
                          style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text('1. Open your email inbox or spam folder.', style: TextStyle(color: textMuted, fontSize: 12)),
                        const SizedBox(height: 3),
                        Text('2. Click the "Confirm your signup" link.', style: TextStyle(color: textMuted, fontSize: 12)),
                        const SizedBox(height: 3),
                        Text('3. Return here and tap "I\'ve Confirmed My Email".', style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ),

                  if (errorMsg != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                      ),
                      child: Text(errorMsg!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                  ],

                  if (successInfoMsg != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
                      ),
                      child: Text(successInfoMsg!, style: TextStyle(color: textPrimary, fontSize: 12)),
                    ),
                  ],

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: isCheckingConfirmation
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            final password = passwordController.text;
                            setModalState(() {
                              isCheckingConfirmation = true;
                              errorMsg = null;
                            });

                            try {
                              final updated = await widget.authRepository.completeLocalToCloudConversion(
                                localSession: _currentSession,
                                email: email,
                                password: password,
                              );
                              authSubscription?.cancel();
                              resendCooldownTimer?.cancel();
                              if (!mounted) return;
                              setState(() => _currentSession = updated);
                              widget.onSessionUpdated(updated);
                              if (modalContext.mounted) {
                                Navigator.of(modalContext).pop();
                              }
                              if (mounted) {
                                UndoToast.show(
                                  context,
                                  message: 'Account upgraded to Cloud! Number: ${updated.phoneNumber}',
                                );
                              }
                            } catch (e) {
                              setModalState(() {
                                isCheckingConfirmation = false;
                                errorMsg = e
                                    .toString()
                                    .replaceFirst('Exception: ', '')
                                    .replaceFirst('AuthException: ', '');
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isCheckingConfirmation ? 'Verifying confirmation...' : "I've Confirmed My Email — Complete Setup",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: (isResending || resendCooldownSeconds > 0)
                            ? null
                            : () async {
                                final email = emailController.text.trim();
                                setModalState(() {
                                  isResending = true;
                                  errorMsg = null;
                                  successInfoMsg = null;
                                });
                                try {
                                  await widget.authRepository.resendConfirmationEmail(email);
                                  startResendCooldown(60);
                                  setModalState(() {
                                    isResending = false;
                                    successInfoMsg = 'Confirmation link resent! Please check your inbox.';
                                  });
                                } catch (e) {
                                  startResendCooldown(60);
                                  setModalState(() {
                                    isResending = false;
                                    errorMsg = e
                                        .toString()
                                        .replaceFirst('Exception: ', '')
                                        .replaceFirst('AuthException: ', '');
                                  });
                                }
                              },
                        icon: const Icon(LucideIcons.refreshCw, size: 14, color: AppColors.accentOrange),
                        label: Text(
                          isResending
                              ? 'Sending...'
                              : resendCooldownSeconds > 0
                                  ? 'Wait ${resendCooldownSeconds}s'
                                  : 'Resend link',
                          style: TextStyle(
                            color: resendCooldownSeconds > 0 ? textMuted : AppColors.accentOrange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          authSubscription?.cancel();
                          resendCooldownTimer?.cancel();
                          setModalState(() {
                            isWaitingForConfirmation = false;
                            errorMsg = null;
                            successInfoMsg = null;
                          });
                        },
                        child: Text('Edit email', style: TextStyle(color: textMuted, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Back up all your tasks, notes, wallets, budgets, and posts to Supabase cloud. You will also get a unique 10-digit Desk phone number assigned by the backend.',
                  style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),

                Text('Email address', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    hintStyle: TextStyle(color: textMuted),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Password', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Minimum 6 characters',
                    hintStyle: TextStyle(color: textMuted),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),

                if (errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(errorMsg!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ],

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: isConverting
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          final password = passwordController.text;
                          if (!email.contains('@')) {
                            setModalState(() => errorMsg = 'Please enter a valid email address');
                            return;
                          }
                          if (password.length < 6) {
                            setModalState(() => errorMsg = 'Password must be at least 6 characters');
                            return;
                          }

                          setModalState(() {
                            isConverting = true;
                            errorMsg = null;
                            successInfoMsg = null;
                          });

                          try {
                            final result = await widget.authRepository.initiateLocalToCloudConversion(
                              localSession: _currentSession,
                              email: email,
                              password: password,
                            );

                            if (result.isCompleted && result.session != null) {
                              if (!mounted) return;
                              setState(() => _currentSession = result.session!);
                              widget.onSessionUpdated(result.session!);
                              if (modalContext.mounted) {
                                Navigator.of(modalContext).pop();
                              }
                              if (mounted) {
                                UndoToast.show(
                                  context,
                                  message: 'Account upgraded to Cloud! Number: ${result.session!.phoneNumber}',
                                );
                              }
                              return;
                            }

                            if (result.needsEmailConfirmation) {
                              setModalState(() {
                                isConverting = false;
                                isWaitingForConfirmation = true;
                                successInfoMsg = 'Confirmation link sent to $email. Please check your inbox!';
                              });

                              // Listen to auth state change if link opens app
                              authSubscription?.cancel();
                              authSubscription =
                                  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
                                if (data.session != null && isWaitingForConfirmation) {
                                  try {
                                    final finished = await widget.authRepository.completeLocalToCloudConversion(
                                      localSession: _currentSession,
                                      email: email,
                                      password: password,
                                    );
                                    authSubscription?.cancel();
                                    if (!mounted) return;
                                    setState(() => _currentSession = finished);
                                    widget.onSessionUpdated(finished);
                                    if (modalContext.mounted) {
                                      Navigator.of(modalContext).pop();
                                    }
                                    if (mounted) {
                                      UndoToast.show(
                                        context,
                                        message:
                                            'Account upgraded to Cloud! Number: ${finished.phoneNumber}',
                                      );
                                    }
                                  } catch (_) {}
                                }
                              });
                            }
                          } catch (e) {
                            setModalState(() {
                              isConverting = false;
                              errorMsg = e
                                  .toString()
                                  .replaceFirst('Exception: ', '')
                                  .replaceFirst('AuthException: ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isConverting ? 'Processing...' : 'Continue with Cloud Account',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      authSubscription?.cancel();
      resendCooldownTimer?.cancel();
    });
  }

  Future<void> _exportData() async {
    try {
      final jsonStr = await widget.authRepository.exportDataJson(_currentSession.accountId);
      final docsDir = await getApplicationDocumentsDirectory();
      final file = File('${docsDir.path}/myday-data.json');
      await file.writeAsString(jsonStr);

      if (mounted) {
        UndoToast.show(context, message: 'Data exported: ${file.path}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _confirmWipeData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          title: Text(
            'Delete All Data?',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Text(
            'Delete all tasks, notes, budget and posts? Fresh seed data will be restored.',
            style: TextStyle(
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.authRepository.wipeAccountData(_currentSession.accountId);
      _loadStats();
      if (mounted) {
        UndoToast.show(context, message: 'All data reset to defaults');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentOrange),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final initial = _currentSession.name.isNotEmpty
        ? _currentSession.name.substring(0, 1).toUpperCase()
        : 'U';

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner & Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF252729), const Color(0xFF1A1B1D)]
                        : [const Color(0xFFE2E0DB), const Color(0xFFECEAE4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _currentSession.coverPath.isNotEmpty && File(_currentSession.coverPath).existsSync()
                    ? Image.file(
                        File(_currentSession.coverPath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 120,
                      )
                    : null,
              ),
              Positioned(
                left: 20,
                bottom: -32,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: _currentSession.avatarPath.isNotEmpty && File(_currentSession.avatarPath).existsSync()
                        ? Image.file(
                            File(_currentSession.avatarPath),
                            fit: BoxFit.cover,
                            width: 68,
                            height: 68,
                          )
                        : Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 44),

          // User Info & Edit button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentSession.name,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${_currentSession.handle} · ${_currentSession.isCloud ? (_currentSession.email ?? "Cloud") : "Local account"}',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              if (_currentSession.isCloud) {
                                Clipboard.setData(ClipboardData(text: _currentSession.phoneNumber));
                                UndoToast.show(context, message: 'Call ID ${_currentSession.phoneNumber} copied to clipboard!');
                              } else {
                                _showConvertToCloudDialog();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _currentSession.isCloud ? AppColors.accentOrange.withOpacity(0.12) : cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _currentSession.isCloud ? AppColors.accentOrange.withOpacity(0.4) : borderColor,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    AppIcons.phone,
                                    size: 13,
                                    color: _currentSession.isCloud ? AppColors.accentOrange : textMuted,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      _currentSession.isCloud
                                          ? 'Call ID: ${_currentSession.phoneNumber}'
                                          : 'Call ID: Cloud Required',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _currentSession.isCloud ? AppColors.accentOrange : textMuted,
                                        fontFamily: _currentSession.isCloud ? 'monospace' : null,
                                      ),
                                    ),
                                  ),
                                  if (_currentSession.isCloud) ...[
                                    const SizedBox(width: 6),
                                    Icon(AppIcons.copy, size: 12, color: AppColors.accentOrange.withOpacity(0.8)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _showEditProfileDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Edit profile',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _currentSession.bio.isNotEmpty
                      ? _currentSession.bio
                      : 'Add a short bio to your profile.',
                  style: TextStyle(
                    color: _currentSession.bio.isNotEmpty ? textPrimary : textMuted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4 Stat tiles: Posts, Done, Day streak, Notes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildStatItem('$_postsCount', 'Posts', textPrimary, textMuted, cardBg, borderColor),
                const SizedBox(width: 8),
                _buildStatItem('$_doneTasksCount', 'Done', textPrimary, textMuted, cardBg, borderColor),
                const SizedBox(width: 8),
                _buildStatItem('$_dayStreak', 'Day streak', textPrimary, textMuted, cardBg, borderColor),
                const SizedBox(width: 8),
                _buildStatItem('$_notesCount', 'Notes', textPrimary, textMuted, cardBg, borderColor),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Settings Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  // App Settings & Preferences
                  if (widget.onOpenSettings != null) ...[
                    _buildSettingRow(
                      title: 'App Settings & Preferences',
                      textColor: textPrimary,
                      trailing: const Icon(AppIcons.settings, size: 18, color: AppColors.accentOrange),
                      onTap: widget.onOpenSettings!,
                    ),
                    Divider(color: borderColor, height: 1),
                  ],

                  // Pocketdesk Call Number
                  _buildSettingRow(
                    title: 'Pocketdesk Call Number',
                    textColor: textPrimary,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _currentSession.isCloud ? _currentSession.phoneNumber : 'Requires Cloud',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _currentSession.isCloud ? AppColors.accentOrange : textMuted,
                              fontWeight: FontWeight.bold,
                              fontFamily: _currentSession.isCloud ? 'monospace' : null,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (_currentSession.isCloud) ...[
                          const SizedBox(width: 8),
                          Icon(AppIcons.copy, size: 16, color: textMuted),
                        ],
                      ],
                    ),
                    onTap: () {
                      if (_currentSession.isCloud) {
                        Clipboard.setData(ClipboardData(text: _currentSession.phoneNumber));
                        UndoToast.show(context, message: 'Call Number ${_currentSession.phoneNumber} copied to clipboard!');
                      } else {
                        _showConvertToCloudDialog();
                      }
                    },
                  ),
                  Divider(color: borderColor, height: 1),

                  // Dark mode toggle
                  _buildSettingRow(
                    title: 'Dark mode',
                    textColor: textPrimary,
                    trailing: Switch.adaptive(
                      value: widget.isDarkMode,
                      activeTrackColor: AppColors.accentOrange,
                      onChanged: (val) => widget.onThemeToggle(),
                    ),
                    onTap: widget.onThemeToggle,
                  ),
                  Divider(color: borderColor, height: 1),

                  // Convert to Cloud Account (if local account)
                  if (!_currentSession.isCloud) ...[
                    _buildSettingRow(
                      title: 'Convert to Cloud Account',
                      textColor: AppColors.accentOrange,
                      trailing: const Icon(LucideIcons.cloudUpload, size: 18, color: AppColors.accentOrange),
                      onTap: _showConvertToCloudDialog,
                    ),
                    Divider(color: borderColor, height: 1),
                  ],

                  // Biometrics toggle (for local and cloud accounts)
                  _buildSettingRow(
                    title: 'Biometric unlock',
                    textColor: textPrimary,
                    trailing: Switch.adaptive(
                      value: _currentSession.isBioEnabled,
                      activeTrackColor: AppColors.accentOrange,
                      onChanged: (val) async {
                        await widget.authRepository.toggleBiometric(_currentSession, val);
                        final updated = UserSession(
                          accountId: _currentSession.accountId,
                          name: _currentSession.name,
                          handle: _currentSession.handle,
                          bio: _currentSession.bio,
                          email: _currentSession.email,
                          isCloud: _currentSession.isCloud,
                          isBioEnabled: val,
                          avatarPath: _currentSession.avatarPath,
                          coverPath: _currentSession.coverPath,
                        );
                        setState(() {
                          _currentSession = updated;
                        });
                        widget.onSessionUpdated(updated);
                      },
                    ),
                    onTap: () async {
                      final val = !_currentSession.isBioEnabled;
                      await widget.authRepository.toggleBiometric(_currentSession, val);
                      final updated = UserSession(
                        accountId: _currentSession.accountId,
                        name: _currentSession.name,
                        handle: _currentSession.handle,
                        bio: _currentSession.bio,
                        email: _currentSession.email,
                        isCloud: _currentSession.isCloud,
                        isBioEnabled: val,
                        avatarPath: _currentSession.avatarPath,
                        coverPath: _currentSession.coverPath,
                      );
                      setState(() {
                        _currentSession = updated;
                      });
                      widget.onSessionUpdated(updated);
                    },
                  ),
                  Divider(color: borderColor, height: 1),

                  // Export JSON
                  _buildSettingRow(
                    title: 'Export my data (JSON)',
                    textColor: textPrimary,
                    trailing: Icon(AppIcons.download, size: 18, color: textMuted),
                    onTap: _exportData,
                  ),
                  Divider(color: borderColor, height: 1),

                  // Delete all data
                  _buildSettingRow(
                    title: 'Delete all data',
                    textColor: AppColors.errorRed,
                    trailing: const Icon(AppIcons.trash2, size: 18, color: AppColors.errorRed),
                    onTap: _confirmWipeData,
                  ),
                  Divider(color: borderColor, height: 1),

                  // Log out
                  _buildSettingRow(
                    title: 'Log out',
                    textColor: textPrimary,
                    trailing: Icon(AppIcons.logOut, size: 18, color: textMuted),
                    onTap: widget.onLogout,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Moments photo grid
          if (_mediaPosts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Moments',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _mediaPosts.length,
                itemBuilder: (context, index) {
                  final post = _mediaPosts[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: post.imagePath.startsWith('data:image') || post.imagePath.startsWith('assets/')
                        ? Image.asset(
                            post.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: cardBg,
                              child: const Icon(AppIcons.image, color: Colors.grey),
                            ),
                          )
                        : Image.file(
                            File(post.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: cardBg,
                              child: const Icon(AppIcons.image, color: Colors.grey),
                            ),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    Color textPrimary,
    Color textMuted,
    Color cardBg,
    Color borderColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required String title,
    required Color textColor,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
