import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_bottom_sheet.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/legacy_pocketdesk_importer.dart';

class PullPocketdeskDataSheet extends StatefulWidget {
  final LegacyPocketdeskImporter importer;
  final String currentAccountId;
  final VoidCallback onDataImported;
  final AuthRepository? authRepository;
  final ValueChanged<UserSession>? onAccountCreated;

  const PullPocketdeskDataSheet({
    super.key,
    required this.importer,
    required this.currentAccountId,
    required this.onDataImported,
    this.authRepository,
    this.onAccountCreated,
  });

  static Future<void> show({
    required BuildContext context,
    required LegacyPocketdeskImporter importer,
    String currentAccountId = '',
    VoidCallback? onDataImported,
    AuthRepository? authRepository,
    ValueChanged<UserSession>? onAccountCreated,
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      title: 'Pull Old Pocketdesk Data',
      child: PullPocketdeskDataSheet(
        importer: importer,
        currentAccountId: currentAccountId,
        onDataImported: onDataImported ?? () {},
        authRepository: authRepository,
        onAccountCreated: onAccountCreated,
      ),
    );
  }

  @override
  State<PullPocketdeskDataSheet> createState() => _PullPocketdeskDataSheetState();
}

class _PullPocketdeskDataSheetState extends State<PullPocketdeskDataSheet>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePin = true;

  bool _isDetecting = true;
  String? _detectedUser;
  List<String> _discoveredUsers = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  LegacyImportSummary? _summary;
  UserSession? _createdSession;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _detectSavedAccount();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectSavedAccount() async {
    List<String> users = [];
    String? selected;
    try {
      final List<String> currentNames = [];
      if (widget.currentAccountId.isNotEmpty) {
        try {
          final current = await widget.importer.db.customSelect(
            'SELECT name, handle, email FROM local_accounts WHERE id = ? LIMIT 1',
            variables: [Variable(widget.currentAccountId)],
          ).getSingleOrNull().timeout(const Duration(seconds: 2));
          if (current != null) {
            final n = current.read<String?>('name');
            final h = current.read<String?>('handle');
            final e = current.read<String?>('email');
            if (n != null && n.isNotEmpty) currentNames.add(n);
            if (h != null && h.isNotEmpty) currentNames.add(h);
            if (e != null && e.isNotEmpty) currentNames.add(e);
          }
        } catch (_) {}
      }

      users = await widget.importer.detectOldPocketdeskUsernames(excludeNames: currentNames).timeout(
        const Duration(seconds: 2),
        onTimeout: () => [],
      );

      if (users.isNotEmpty) {
        selected = users.first;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isDetecting = false;
        _discoveredUsers = users;
        _detectedUser = selected;
        if (_detectedUser != null && _detectedUser!.isNotEmpty) {
          _usernameController.text = _detectedUser!;
        }
      });
    }
  }

  Future<void> _handleVerifyAndPull() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final pin = _pinController.text.trim();

    if (username.isEmpty) {
      setState(() => _errorMessage = 'Please enter your old username.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your old password.');
      return;
    }
    if (widget.currentAccountId.isEmpty && pin.length != 4) {
      setState(() => _errorMessage = 'Please choose a 4-digit PIN for this device.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final isValid = await widget.importer.verifyCredentials(
      username: username,
      passwordOrPin: password,
    );

    if (!isValid) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage =
              'Incorrect password for "$username". Please check your old credentials.';
        });
      }
      return;
    }

    String targetId = widget.currentAccountId;
    UserSession? session;

    if (targetId.isEmpty && widget.authRepository != null) {
      try {
        session = await widget.authRepository!.createLocalAccount(
          name: username,
          pin: pin,
        );
        targetId = session.accountId;
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Failed to create local account: $e';
          });
        }
        return;
      }
    }

    // Pull data
    final summary = await widget.importer.pullOldPocketdeskData(
      targetAccountId: targetId,
      username: username,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _summary = summary;
        _createdSession = session;
      });
      _animCtrl.forward();
      widget.onDataImported();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDetecting) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accentOrange),
              SizedBox(height: 14),
              Text('Checking local database records...', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (_summary != null) {
      return _buildSuccessView();
    }

    return _buildFormView();
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Detected account callout
        if (_detectedUser != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.check, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saved Pocketdesk account discovered: "$_detectedUser"',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_discoveredUsers.length > 1) ...[
            const SizedBox(height: 10),
            Text(
              'FOUND POCKETDESK ACCOUNTS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: context.appMuted,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _discoveredUsers.map((u) {
                final isSel = _usernameController.text.trim().toLowerCase() ==
                    u.trim().toLowerCase();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _usernameController.text = u;
                      _detectedUser = u;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.accentOrange.withValues(alpha: 0.18)
                          : context.appSurface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? AppColors.accentOrange : context.appLine,
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.user,
                          size: 13,
                          color: isSel ? AppColors.accentOrange : context.appMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          u,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? AppColors.accentOrange : context.appText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
        ],

        // Username Field
        Text(
          'USERNAME',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: context.appMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.appSurface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.appLine, width: 1),
          ),
          child: TextField(
            controller: _usernameController,
            style: TextStyle(color: context.appText, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Enter username',
              hintStyle: TextStyle(color: context.appMuted),
              prefixIcon: Icon(AppIcons.user, size: 18, color: context.appMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Password / PIN Field
        Text(
          widget.currentAccountId.isEmpty ? 'OLD POCKETDESK PASSWORD' : 'PASSWORD OR 4-DIGIT PIN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: context.appMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.appSurface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.appLine, width: 1),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: context.appText, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Enter your alphanumeric password',
              hintStyle: TextStyle(color: context.appMuted),
              prefixIcon: Icon(AppIcons.key, size: 18, color: context.appMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: context.appMuted,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _handleVerifyAndPull(),
          ),
        ),

        if (widget.currentAccountId.isEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'CHOOSE NEW 4-DIGIT PIN FOR THIS DEVICE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: context.appMuted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: context.appSurface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appLine, width: 1),
            ),
            child: TextField(
              controller: _pinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: TextStyle(color: context.appText, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. 2211',
                hintStyle: TextStyle(color: context.appMuted),
                prefixIcon: Icon(Icons.pin, size: 18, color: context.appMuted),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: context.appMuted,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _handleVerifyAndPull(),
            ),
          ),
        ],

        // Error Banner
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        // Info Note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appLine.withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.info, size: 15, color: context.appMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pocketdesk decrypts and imports your tasks, notes, wallets, expenses, and media posts directly from your offline database.',
                  style: TextStyle(fontSize: 11, color: context.appMuted, height: 1.35),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Submit Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: _isSubmitting ? null : _handleVerifyAndPull,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.download, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Verify & Pull Pocketdesk Data',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    final s = _summary!;
    return ScaleTransition(
      scale: _scaleAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: const Icon(AppIcons.check, size: 32, color: Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Data Pulled Successfully!',
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: context.appText),
          ),
          const SizedBox(height: 4),
          Text(
            'All records from "${s.detectedUsername}" have been integrated into your workspace.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: context.appMuted),
          ),
          const SizedBox(height: 18),

          // Import stats grid
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.appSurface2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appLine),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildStatPill('Tasks', s.tasksCount, AppIcons.tasks),
                _buildStatPill('Notes', s.notesCount, AppIcons.notes),
                _buildStatPill('Wallets', s.walletsCount, AppIcons.wallet),
                _buildStatPill('Transactions', s.transactionsCount, AppIcons.money),
                _buildStatPill('Posts', s.postsCount, AppIcons.camera),
                _buildStatPill('Events', s.eventsCount, AppIcons.calendar),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () {
              final session = _createdSession;
              Navigator.of(context).pop();
              if (session != null && widget.onAccountCreated != null) {
                widget.onAccountCreated!(session);
              }
            },
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, int count, IconData icon) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appLine.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.accentOrange),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: context.appMuted),
          ),
        ],
      ),
    );
  }
}
