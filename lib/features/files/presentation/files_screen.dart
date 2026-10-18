import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_bottom_sheet.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../data/files_repository.dart';

class FilesScreen extends StatefulWidget {
  final FilesRepository filesRepository;
  final String accountId;
  final UserSession? session;

  const FilesScreen({
    super.key,
    required this.filesRepository,
    required this.accountId,
    this.session,
  });

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<MyDayFile> _myFiles = [];
  List<MyDayFile> _friendsFiles = [];
  List<MyDayFile> _everyoneFiles = [];

  bool _isLoading = true;
  bool _isUploading = false;
  String _downloadingFileId = '';
  bool _showMyUploads = true;
  String _sharedFilter = 'all';

  bool get _isLocalAccount =>
      widget.session != null ? !widget.session!.isCloud : widget.accountId.startsWith('local_');

  String get _myPhone => widget.session?.phoneNumber ?? '';
  String get _myName => widget.session?.name ?? 'Pocketdesk User';

  @override
  void initState() {
    super.initState();
    _loadAllFiles();
  }

  Future<void> _loadAllFiles() async {
    setState(() => _isLoading = true);
    try {
      final myFiles = await widget.filesRepository.getFiles(widget.accountId);
      List<MyDayFile> friends = [];
      List<MyDayFile> everyone = [];

      if (!_isLocalAccount) {
        final results = await Future.wait([
          widget.filesRepository.getFriendsFiles(_myPhone),
          widget.filesRepository.getEveryoneFiles(),
        ]);
        friends = results[0];
        everyone = results[1];
      }

      if (mounted) {
        setState(() {
          _myFiles = myFiles;
          _friendsFiles = friends;
          _everyoneFiles = everyone;
        });
      }
    } catch (e) {
      debugPrint('Error loading files: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_rounded;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
        return Icons.audio_file_rounded;
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
        return Icons.video_file_rounded;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip_rounded;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'md':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf':
        return AppColors.errorRed;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.teal;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Colors.purple;
      case 'zip':
      case 'rar':
        return AppColors.amber;
      case 'doc':
      case 'docx':
      case 'txt':
        return AppColors.accent;
      default:
        return AppColors.accent;
    }
  }

  // --- 1. UPLOAD FILE FLOW ---
  Future<void> _startUploadFlow() async {
    if (_isLocalAccount) {
      _showCloudRequiredDialog();
      return;
    }

    String selectedMode = 'everyone';
    final pinCtrl = TextEditingController();
    final friendPhoneCtrl = TextEditingController();

    final config = await AppBottomSheet.show<_UploadConfig>(
      context: context,
      title: 'Upload & Share File',
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Choose audience & privacy level for your file upload:',
                          style: TextStyle(color: context.appText, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Option 1: Everyone (Public)
                _buildShareModeCard(
                  context: context,
                  title: 'Everyone (Public)',
                  subtitle: 'Shared to all users across Community feed. Open access for anyone to download.',
                  badgeText: 'PUBLIC',
                  icon: Icons.public_rounded,
                  accentColor: AppColors.accent,
                  isSelected: selectedMode == 'everyone',
                  onTap: () => setSheetState(() => selectedMode = 'everyone'),
                ),
                const SizedBox(height: 12),

                // Option 2: Friends Share (Phone Number)
                _buildShareModeCard(
                  context: context,
                  title: 'Friends Share',
                  subtitle: 'Direct transfer to your friend. Delivered securely into their personal Files inbox.',
                  badgeText: 'FRIENDS',
                  icon: Icons.people_alt_rounded,
                  accentColor: AppColors.successGreen,
                  isSelected: selectedMode == 'friends',
                  onTap: () => setSheetState(() => selectedMode = 'friends'),
                ),
                if (selectedMode == 'friends') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.45), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.successGreen.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.phone_android_rounded, size: 16, color: AppColors.successGreen),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Friend's 10-Digit Phone Number",
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: friendPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: TextStyle(
                            color: context.appText,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            isDense: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('+977', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            hintText: '98XXXXXXXX',
                            hintStyle: TextStyle(
                              color: context.appMuted.withValues(alpha: 0.5),
                              letterSpacing: 0,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: context.appBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.appLine),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.appLine),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.successGreen, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Option 3: Private (PIN Locked)
                _buildShareModeCard(
                  context: context,
                  title: 'Private (PIN Locked)',
                  subtitle: 'Passcode encrypted. Anyone with your 4 to 6-digit PIN can unlock via "Get File".',
                  badgeText: 'PRIVATE',
                  icon: Icons.lock_rounded,
                  accentColor: AppColors.amber,
                  isSelected: selectedMode == 'private',
                  onTap: () => setSheetState(() => selectedMode = 'private'),
                ),
                if (selectedMode == 'private') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.45), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.amber.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.key_rounded, size: 16, color: AppColors.amber),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Set Secret 4-6 Digit Access PIN',
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: pinCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: TextStyle(
                            color: context.appText,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            hintText: '• • • •',
                            hintStyle: TextStyle(
                              color: context.appMuted.withValues(alpha: 0.5),
                              letterSpacing: 2,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: context.appBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.appLine),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.appLine),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),

                // Primary Action Button
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFE55D00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.cloud_upload_rounded, size: 22),
                    label: const Text(
                      'Choose File & Upload',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                    ),
                    onPressed: () {
                      if (selectedMode == 'private' && pinCtrl.text.trim().isEmpty) {
                        UndoToast.show(context, message: 'Please set a PIN for your private file');
                        return;
                      }
                      if (selectedMode == 'friends' && friendPhoneCtrl.text.trim().isEmpty) {
                        UndoToast.show(context, message: "Please enter your friend's phone number");
                        return;
                      }
                      Navigator.pop(
                        sheetCtx,
                        _UploadConfig(
                          shareType: selectedMode,
                          pin: pinCtrl.text.trim(),
                          friendPhone: friendPhoneCtrl.text.trim(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (config == null) return;

    setState(() => _isUploading = true);
    try {
      final file = await widget.filesRepository.pickAndUploadFile(
        accountId: widget.accountId,
        uploaderName: _myName,
        uploaderPhone: _myPhone,
        shareType: config.shareType,
        pin: config.pin,
        friendPhoneNumber: config.friendPhone,
      );

      if (file != null && mounted) {
        UndoToast.show(
          context,
          message: '✓ "${file.name}" uploaded to cloud bucket (${_getShareTypeLabel(file.shareType)})',
        );
        _loadAllFiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // --- 2. GET FILE BY PIN FLOW ---
  Future<void> _startGetFileByPinFlow() async {
    final pinCtrl = TextEditingController();
    bool isSearching = false;
    MyDayFile? foundFile;
    String? searchError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.appSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.key_rounded, color: AppColors.amber, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Get File by PIN',
                    style: AppTypography.h3.copyWith(color: context.appText, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the secret PIN shared with you to unlock and retrieve the private file:',
                  style: TextStyle(color: context.appMuted, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.appBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appLine),
                  ),
                  child: TextField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: TextStyle(
                      color: context.appText,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 4,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter PIN (e.g. 4829)',
                      hintStyle: TextStyle(letterSpacing: 0, fontSize: 13),
                      border: InputBorder.none,
                      icon: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.amber),
                    ),
                  ),
                ),
                if (searchError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    searchError!,
                    style: const TextStyle(color: AppColors.errorRed, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
                if (foundFile != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(_getFileIcon(foundFile!.name), color: _getFileColor(foundFile!.name), size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                foundFile!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: context.appText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatSize(foundFile!.sizeBytes)} • by ${foundFile!.uploaderName}',
                                style: TextStyle(fontSize: 11, color: context.appMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              if (foundFile == null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSearching
                      ? null
                      : () async {
                          final pin = pinCtrl.text.trim();
                          if (pin.isEmpty) {
                            setDialogState(() => searchError = 'Please enter a PIN');
                            return;
                          }
                          setDialogState(() {
                            isSearching = true;
                            searchError = null;
                          });

                          try {
                            final file = await widget.filesRepository.getFileByPin(pin);
                            if (file != null) {
                              setDialogState(() {
                                foundFile = file;
                                isSearching = false;
                              });
                            } else {
                              setDialogState(() {
                                searchError = 'No file found matching PIN "$pin". Please verify and try again.';
                                isSearching = false;
                              });
                            }
                          } catch (e) {
                            setDialogState(() {
                              searchError = 'Error fetching file: $e';
                              isSearching = false;
                            });
                          }
                        },
                  child: isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Unlock & Fetch'),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download File'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _downloadFile(foundFile!);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  // --- 3. DOWNLOAD FILE FLOW ---
  Future<void> _downloadFile(MyDayFile file) async {
    setState(() => _downloadingFileId = file.id);
    try {
      final downloaded = await widget.filesRepository.downloadFile(file);
      if (downloaded != null && mounted) {
        UndoToast.show(
          context,
          message: '✓ "${file.name}" saved to device',
          actionLabel: 'Open',
          onUndo: () async {
            try {
              await launchUrl(Uri.file(downloaded.path));
            } catch (_) {
              Clipboard.setData(ClipboardData(text: downloaded.path));
              if (mounted) {
                UndoToast.show(context, message: 'Path copied: ${downloaded.path}');
              }
            }
          },
        );
        _loadAllFiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingFileId = '');
      }
    }
  }

  Future<void> _deleteFile(MyDayFile file) async {
    await widget.filesRepository.deleteFile(file.id, accountId: widget.accountId);
    _loadAllFiles();
    if (mounted) {
      UndoToast.show(
        context,
        message: 'Deleted "${file.name}"',
        actionLabel: 'Undo',
        onUndo: () async {
          await widget.filesRepository.restoreFile(file.id);
          _loadAllFiles();
        },
      );
    }
  }

  void _showCloudRequiredDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.cloud_outlined, color: AppColors.accent, size: 24),
            const SizedBox(width: 10),
            Text('Cloud Account Required', style: AppTypography.h3.copyWith(color: context.appText)),
          ],
        ),
        content: Text(
          'Cloud bucket storage and file sharing across Everyone and Friends are exclusively available on free Cloud accounts. Local accounts keep all records strictly on this device.',
          style: TextStyle(color: context.appMuted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _getShareTypeLabel(String type) {
    switch (type) {
      case 'everyone':
      case 'public':
        return 'Everyone';
      case 'private':
        return 'Private (PIN)';
      case 'friends':
        return 'Friends Share';
      default:
        return type;
    }
  }

  Widget _buildShareModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final surface = context.appSurface;
    final line = context.appLine;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: accentColor.withValues(alpha: 0.12),
        highlightColor: accentColor.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: 0.08) : surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? accentColor : line.withValues(alpha: 0.65),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [accentColor.withValues(alpha: 0.25), accentColor.withValues(alpha: 0.12)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected ? accentColor.withValues(alpha: 0.4) : Colors.transparent,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isSelected ? accentColor : context.appText,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isSelected ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? accentColor : context.appMuted.withValues(alpha: 0.35),
                    width: isSelected ? 2.2 : 1.5,
                  ),
                  color: isSelected ? accentColor : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocalAccount) {
      return _buildBlockedLocalAccountView();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadAllFiles,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Action Header & Button Bar
            _buildTopActionBar(),

            const SizedBox(height: 16),

            if (_isUploading) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Uploading file to cloud bucket...',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. MY UPLOADED FILES SECTION (UP)
            _buildMyUploadsSection(),

            const SizedBox(height: 20),

            // 3. UNIFIED BIG BOX: EVERYONE'S & FRIENDS SHARED FILES (DOWN)
            _buildUnifiedSharedFilesBox(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- Top Action Bar ---
  Widget _buildTopActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_done_rounded, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud Storage & Sharing',
                      style: AppTypography.h3.copyWith(color: context.appText, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _myPhone.isNotEmpty ? 'Your Phone: $_myPhone' : 'Connected to Supabase Bucket',
                      style: TextStyle(color: context.appMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Upload Button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 17),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Upload File',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                  onPressed: _startUploadFlow,
                ),
              ),
              const SizedBox(width: 8),
              // Get File by PIN Button
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.appText,
                    side: BorderSide(color: context.appLine, width: 1.3),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.key_rounded, size: 17, color: AppColors.amber),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Get File by PIN',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                  onPressed: _startGetFileByPinFlow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Big Unified Shared Files Box (Down below My Uploads) ---
  Widget _buildUnifiedSharedFilesBox() {
    final List<({MyDayFile file, bool isFriend})> combined = [];
    for (final f in _friendsFiles) {
      combined.add((file: f, isFriend: true));
    }
    for (final f in _everyoneFiles) {
      if (!combined.any((c) => c.file.id == f.id)) {
        combined.add((file: f, isFriend: false));
      }
    }

    final filtered = combined.where((item) {
      if (_sharedFilter == 'friends') return item.isFriend;
      if (_sharedFilter == 'everyone') return !item.isFriend;
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appLine, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of the Big Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.folder_shared_rounded, color: AppColors.accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Everyone's & Shared Files",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: context.appText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${combined.length}',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Shared by friends and community members',
                            style: TextStyle(color: context.appMuted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Filter Tabs (All / Friends / Everyone)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All (${combined.length})'),
                      const SizedBox(width: 6),
                      _buildFilterChip('friends', 'Friends (${_friendsFiles.length})', icon: Icons.people_alt_rounded),
                      const SizedBox(width: 6),
                      _buildFilterChip('everyone', 'Everyone (${_everyoneFiles.length})', icon: Icons.public_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: context.appLine, height: 1),

          // File List inside Big Box
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      _sharedFilter == 'friends'
                          ? Icons.people_outline_rounded
                          : Icons.public_off_rounded,
                      color: context.appMuted,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sharedFilter == 'friends'
                          ? 'No files shared by friends yet'
                          : (_sharedFilter == 'everyone'
                              ? 'No public files shared yet'
                              : 'No shared files found'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sharedFilter == 'friends'
                          ? 'Files shared to your phone number will appear here.'
                          : 'Public files uploaded by everyone will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.appMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(color: context.appLine, height: 1),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return _buildSharedItemRow(file: item.file, isFriend: item.isFriend);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {IconData? icon}) {
    final isSelected = _sharedFilter == key;
    return InkWell(
      onTap: () => setState(() => _sharedFilter = key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : context.appSurface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accent : context.appLine,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: isSelected ? Colors.white : context.appMuted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : context.appText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedItemRow({required MyDayFile file, required bool isFriend}) {
    final isDownloading = _downloadingFileId == file.id;
    final dateStr = DateFormat('MMM d').format(DateTime.fromMillisecondsSinceEpoch(file.createdAt));
    final fileColor = _getFileColor(file.name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Extension / Type Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: fileColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getFileIcon(file.name), color: fileColor, size: 19),
          ),
          const SizedBox(width: 10),

          // File Info + Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 3),
                // Badges Row with prominent friend/global logos
                Wrap(
                  spacing: 5,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Distinctive Friend vs Everyone Logo & Badge
                    if (isFriend)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.35), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 10.5, color: AppColors.successGreen),
                            const SizedBox(width: 3),
                            Text(
                              file.uploaderName.isNotEmpty ? file.uploaderName : file.uploaderPhone,
                              style: const TextStyle(
                                color: AppColors.successGreen,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.public_rounded, size: 10.5, color: AppColors.accent),
                            const SizedBox(width: 3),
                            Text(
                              file.uploaderName.isNotEmpty ? file.uploaderName : 'Everyone',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(_formatSize(file.sizeBytes), style: TextStyle(fontSize: 10.5, color: context.appMuted)),
                    Text('•', style: TextStyle(fontSize: 10, color: context.appMuted)),
                    Text(dateStr, style: TextStyle(fontSize: 10.5, color: context.appMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Download Action Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: isDownloading
                ? const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.8),
                  )
                : const Icon(Icons.download_rounded, size: 13),
            label: Text(
              isDownloading ? '...' : 'Get',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: isDownloading ? null : () => _downloadFile(file),
          ),
        ],
      ),
    );
  }



  // --- My Uploads Section ---
  Widget _buildMyUploadsSection() {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _showMyUploads = !_showMyUploads),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.folder_shared_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'My Uploaded Files (${_myFiles.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: context.appText,
                      ),
                    ),
                  ),
                  Icon(
                    _showMyUploads ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: context.appMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_showMyUploads) ...[
            Divider(color: context.appLine, height: 1),
            if (_myFiles.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'You have not uploaded any files yet.',
                    style: TextStyle(color: context.appMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myFiles.length,
                separatorBuilder: (_, __) => Divider(color: context.appLine, height: 1),
                itemBuilder: (context, index) {
                  final file = _myFiles[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(_getFileIcon(file.name), color: _getFileColor(file.name), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appText),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(_formatSize(file.sizeBytes), style: TextStyle(fontSize: 11, color: context.appMuted)),
                                  Text('•', style: TextStyle(fontSize: 10, color: context.appMuted)),
                                  _buildMyFileBadge(file),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (file.isPrivate && file.pin.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            color: AppColors.amber,
                            tooltip: 'Copy PIN (${file.pin})',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: file.pin));
                              UndoToast.show(context, message: 'PIN "${file.pin}" copied to clipboard');
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.download_rounded, size: 18),
                          color: AppColors.accent,
                          tooltip: 'Download',
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          onPressed: () => _downloadFile(file),
                        ),
                        IconButton(
                          icon: const Icon(AppIcons.trash, size: 16),
                          color: AppColors.errorRed,
                          tooltip: 'Delete',
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          onPressed: () => _deleteFile(file),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyFileBadge(MyDayFile file) {
    if (file.isPrivate) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          file.pin.isNotEmpty ? 'Private (PIN: ${file.pin})' : 'Private',
          style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
    } else if (file.isFriends) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          file.friendPhoneNumber.isNotEmpty ? 'Friend: ${file.friendPhoneNumber}' : 'Friends Share',
          style: const TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Everyone',
          style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
    }
  }



  // --- Blocked Local Account View ---
  Widget _buildBlockedLocalAccountView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cloud Account Required',
              style: AppTypography.h2.copyWith(color: context.appText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Cloud Storage, Friends Share by Phone, and Everyone Public Files require a free Cloud account with Supabase bucket integration.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: context.appMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appLine),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.info, color: AppColors.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: Switch or create a Cloud account in Settings to unlock Cloud Buckets, Friends Share, and Everyone Files.',
                      style: TextStyle(color: context.appText, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadConfig {
  final String shareType;
  final String pin;
  final String friendPhone;

  _UploadConfig({
    required this.shareType,
    required this.pin,
    required this.friendPhone,
  });
}
