import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'supabase_auth_service.dart';

enum AccountType { local, cloud }

enum CloudPlan { free, pro }

class AccountPlanState {
  const AccountPlanState({
    this.accountType = AccountType.local,
    this.cloudPlan = CloudPlan.free,
    this.isProActive = false,
    this.isActive = true,
    this.isProApprovalPending = false,
    this.isBlacklisted = false,
    this.storageUsedBytes = 0,
    this.cloudEmail,
    this.cloudUserId,
  });

  final AccountType accountType;
  final CloudPlan cloudPlan;
  final bool isProActive;
  final bool isActive;
  final bool isProApprovalPending;
  final bool isBlacklisted;
  final int storageUsedBytes;
  final String? cloudEmail;
  final String? cloudUserId;

  int get storageLimitBytes => (cloudPlan == CloudPlan.pro || isProActive)
      ? 10 * 1024 * 1024 * 1024 // 10 GB Pro
      : 500 * 1024 * 1024; // 500 MB Free

  double get storageProgress =>
      (storageUsedBytes / storageLimitBytes).clamp(0.0, 1.0);

  AccountPlanState copyWith({
    AccountType? accountType,
    CloudPlan? cloudPlan,
    bool? isProActive,
    bool? isActive,
    bool? isProApprovalPending,
    bool? isBlacklisted,
    int? storageUsedBytes,
    String? cloudEmail,
    String? cloudUserId,
  }) {
    return AccountPlanState(
      accountType: accountType ?? this.accountType,
      cloudPlan: cloudPlan ?? this.cloudPlan,
      isProActive: isProActive ?? this.isProActive,
      isActive: isActive ?? this.isActive,
      isProApprovalPending: isProApprovalPending ?? this.isProApprovalPending,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      cloudEmail: cloudEmail ?? this.cloudEmail,
      cloudUserId: cloudUserId ?? this.cloudUserId,
    );
  }
}

class AccountPlanNotifier extends StateNotifier<AccountPlanState> {
  AccountPlanNotifier() : super(const AccountPlanState()) {
    _loadState();
  }

  static const _storage = FlutterSecureStorage();

  Future<void> _loadState() async {
    try {
      final typeStr = await _storage.read(key: 'account_type');
      final planStr = await _storage.read(key: 'cloud_plan');
      final pendingStr = await _storage.read(key: 'pro_pending');
      final blacklistedStr = await _storage.read(key: 'blacklisted');
      final emailStr = await _storage.read(key: 'cloud_email');
      final userIdStr = await _storage.read(key: 'cloud_user_id');
      final isProActiveStr = await _storage.read(key: 'is_pro_active');

      state = AccountPlanState(
        accountType: typeStr == 'cloud' ? AccountType.cloud : AccountType.local,
        cloudPlan: planStr == 'pro' ? CloudPlan.pro : CloudPlan.free,
        isProActive: isProActiveStr == 'true' || planStr == 'pro',
        isProApprovalPending: pendingStr == 'true',
        isBlacklisted: blacklistedStr == 'true',
        storageUsedBytes: 0,
        cloudEmail: emailStr,
        cloudUserId: userIdStr,
      );

      if (emailStr != null && emailStr.isNotEmpty) {
        await syncCloudProfile(emailStr);
      }
    } catch (_) {}
  }

  Future<void> syncCloudProfile(String email) async {
    final res = await SupabaseAuthService.syncProfileFromSupabase(email: email);
    final plan = res.cloudPlan == 'pro' ? CloudPlan.pro : CloudPlan.free;
    await _storage.write(key: 'account_type', value: 'cloud');
    await _storage.write(key: 'cloud_plan', value: plan.name);
    await _storage.write(key: 'is_pro_active', value: res.isProActive.toString());
    await _storage.write(key: 'cloud_email', value: email);
    if (res.userId != null) {
      await _storage.write(key: 'cloud_user_id', value: res.userId!);
    }

    state = state.copyWith(
      accountType: AccountType.cloud,
      cloudPlan: plan,
      isProActive: res.isProActive,
      isActive: res.isActive,
      cloudEmail: email,
      cloudUserId: res.userId ?? state.cloudUserId,
    );
  }

  Future<void> selectAccountType(AccountType type) async {
    await _storage.write(key: 'account_type', value: type.name);
    state = state.copyWith(accountType: type);
  }

  Future<void> selectCloudPlan(CloudPlan plan) async {
    await _storage.write(key: 'cloud_plan', value: plan.name);
    // Note: Do NOT mark pro_pending as true here until account creation / request is actually submitted!
    state = state.copyWith(
      cloudPlan: plan,
      isProApprovalPending: false,
    );
  }

  Future<void> convertToCloudAccount({required String email, required CloudPlan plan}) async {
    await _storage.write(key: 'account_type', value: 'cloud');
    await _storage.write(key: 'cloud_plan', value: plan.name);
    final isPending = plan == CloudPlan.pro;
    if (isPending) {
      await _storage.write(key: 'pro_pending', value: 'true');
    } else {
      await _storage.delete(key: 'pro_pending');
    }
    await _storage.write(key: 'cloud_email', value: email);
    state = state.copyWith(
      accountType: AccountType.cloud,
      cloudPlan: plan,
      isProApprovalPending: isPending,
      cloudEmail: email,
    );
  }

  Future<void> markProPending(bool pending) async {
    if (pending) {
      await _storage.write(key: 'pro_pending', value: 'true');
    } else {
      await _storage.delete(key: 'pro_pending');
    }
    state = state.copyWith(isProApprovalPending: pending);
  }

  Future<void> resetToLocalAccount() async {
    await _storage.deleteAll();
    state = const AccountPlanState(
      accountType: AccountType.local,
      cloudPlan: CloudPlan.free,
      isProApprovalPending: false,
      isProActive: false,
    );
  }

  Future<void> updateBlacklistStatus(bool blacklisted) async {
    await _storage.write(key: 'blacklisted', value: blacklisted.toString());
    state = state.copyWith(isBlacklisted: blacklisted);
  }
}

final accountPlanProvider =
    StateNotifierProvider<AccountPlanNotifier, AccountPlanState>(
  (ref) => AccountPlanNotifier(),
);
