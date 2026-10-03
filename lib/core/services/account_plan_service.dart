import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AccountType { local, cloud }

enum CloudPlan { free, pro }

class AccountPlanState {
  const AccountPlanState({
    this.accountType = AccountType.local,
    this.cloudPlan = CloudPlan.free,
    this.isProApprovalPending = false,
    this.isBlacklisted = false,
    this.storageUsedBytes = 0,
  });

  final AccountType accountType;
  final CloudPlan cloudPlan;
  final bool isProApprovalPending;
  final bool isBlacklisted;
  final int storageUsedBytes;

  int get storageLimitBytes => cloudPlan == CloudPlan.free
      ? 500 * 1024 * 1024 // 500 MB Free
      : 10 * 1024 * 1024 * 1024; // 10 GB Pro

  double get storageProgress =>
      (storageUsedBytes / storageLimitBytes).clamp(0.0, 1.0);

  AccountPlanState copyWith({
    AccountType? accountType,
    CloudPlan? cloudPlan,
    bool? isProApprovalPending,
    bool? isBlacklisted,
    int? storageUsedBytes,
  }) {
    return AccountPlanState(
      accountType: accountType ?? this.accountType,
      cloudPlan: cloudPlan ?? this.cloudPlan,
      isProApprovalPending: isProApprovalPending ?? this.isProApprovalPending,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
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

      state = AccountPlanState(
        accountType: typeStr == 'cloud' ? AccountType.cloud : AccountType.local,
        cloudPlan: planStr == 'pro' ? CloudPlan.pro : CloudPlan.free,
        isProApprovalPending: pendingStr == 'true',
        isBlacklisted: blacklistedStr == 'true',
        storageUsedBytes: 42 * 1024 * 1024, // 42MB default mock usage
      );
    } catch (_) {}
  }

  Future<void> selectAccountType(AccountType type) async {
    await _storage.write(key: 'account_type', value: type.name);
    state = state.copyWith(accountType: type);
  }

  Future<void> selectCloudPlan(CloudPlan plan) async {
    await _storage.write(key: 'cloud_plan', value: plan.name);
    final isPending = plan == CloudPlan.pro;
    await _storage.write(key: 'pro_pending', value: isPending.toString());
    state = state.copyWith(cloudPlan: plan, isProApprovalPending: isPending);
  }

  Future<void> convertToCloudAccount({required String email, required CloudPlan plan}) async {
    await _storage.write(key: 'account_type', value: 'cloud');
    await _storage.write(key: 'cloud_plan', value: plan.name);
    final isPending = plan == CloudPlan.pro;
    await _storage.write(key: 'pro_pending', value: isPending.toString());
    await _storage.write(key: 'cloud_email', value: email);
    state = state.copyWith(
      accountType: AccountType.cloud,
      cloudPlan: plan,
      isProApprovalPending: isPending,
    );
  }

  Future<void> resetToLocalAccount() async {
    await _storage.delete(key: 'account_type');
    await _storage.delete(key: 'cloud_plan');
    await _storage.delete(key: 'pro_pending');
    await _storage.delete(key: 'cloud_email');
    state = const AccountPlanState(
      accountType: AccountType.local,
      cloudPlan: CloudPlan.free,
      isProApprovalPending: false,
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
