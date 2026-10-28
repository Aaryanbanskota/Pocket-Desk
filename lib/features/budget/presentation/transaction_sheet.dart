import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_bottom_sheet.dart';
import '../data/budget_repository.dart';
import 'wallet_sheet.dart';

class TransactionSheet {
  static Future<void> show({
    required BuildContext context,
    MyDayTransaction? transactionToEdit,
    required List<MyDayWallet> wallets,
    required String defaultWalletId,
    required FutureOr<void> Function({
      required String type,
      required int amountMinor,
      required String category,
      required String walletId,
      String? toWalletId,
      required int transactionTime,
      required String note,
    }) onSave,
    VoidCallback? onDelete,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: transactionToEdit != null ? 'Edit transaction' : 'New transaction',
      child: _TransactionSheetContent(
        transactionToEdit: transactionToEdit,
        wallets: wallets,
        defaultWalletId: defaultWalletId,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  static Future<void> showForAccount({
    required BuildContext context,
    required BudgetRepository budgetRepository,
    required String accountId,
    MyDayTransaction? transaction,
    VoidCallback? onSaved,
  }) async {
    final wallets = await budgetRepository.getWallets(accountId);
    if (!context.mounted) return;
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a wallet first to start tracking transactions.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return WalletSheet.showForAccount(
        context: context,
        budgetRepository: budgetRepository,
        accountId: accountId,
        onSaved: onSaved,
      );
    }
    return show(
      context: context,
      transactionToEdit: transaction,
      wallets: wallets,
      defaultWalletId: wallets.first.id,
      onSave: ({
        required String type,
        required int amountMinor,
        required String category,
        required String walletId,
        String? toWalletId,
        required int transactionTime,
        required String note,
      }) async {
        if (transaction == null) {
          await budgetRepository.addTransaction(
            accountId: accountId,
            walletId: walletId,
            toWalletId: toWalletId,
            type: type,
            category: category,
            amountMinor: amountMinor,
            transactionTime: transactionTime,
            note: note,
          );
        } else {
          await budgetRepository.updateTransaction(
            MyDayTransaction(
              id: transaction.id,
              accountId: accountId,
              walletId: walletId,
              toWalletId: toWalletId,
              type: type,
              category: category,
              amount: amountMinor,
              transactionTime: transactionTime,
              note: note,
            ),
          );
        }
        onSaved?.call();
      },
      onDelete: transaction != null
          ? () async {
              await budgetRepository.deleteTransaction(transaction.id);
              onSaved?.call();
            }
          : null,
    );
  }
}

class _TransactionSheetContent extends StatefulWidget {
  final MyDayTransaction? transactionToEdit;
  final List<MyDayWallet> wallets;
  final String defaultWalletId;
  final FutureOr<void> Function({
    required String type,
    required int amountMinor,
    required String category,
    required String walletId,
    String? toWalletId,
    required int transactionTime,
    required String note,
  }) onSave;
  final VoidCallback? onDelete;

  const _TransactionSheetContent({
    this.transactionToEdit,
    required this.wallets,
    required this.defaultWalletId,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_TransactionSheetContent> createState() =>
      _TransactionSheetContentState();
}

class _TransactionSheetContentState extends State<_TransactionSheetContent> {
  late String _type; // 'Expense' | 'Income' | 'Transfer'
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _category;
  late String _walletId;
  String? _toWalletId;
  late DateTime _transactionDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final t = widget.transactionToEdit;
    _type = t?.type ?? 'Expense';
    _amountController = TextEditingController(
      text: t != null ? (t.amount / 100.0).toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: t?.note ?? '');
    _category = t?.category ?? 'Food';
    _walletId = t?.walletId ?? widget.defaultWalletId;
    _toWalletId = t?.toWalletId;
    _transactionDate = t != null
        ? DateTime.fromMillisecondsSinceEpoch(t.transactionTime)
        : DateTime.now();
  }

  Future<void> _onSavePressed() async {
    final amountVal = double.tryParse(_amountController.text);
    if (amountVal == null || amountVal <= 0) {
      setState(() => _errorMessage = 'Enter a valid amount');
      return;
    }

    final amountMinor = (amountVal * 100).round();

    if (_type == 'Transfer' && (_toWalletId == null || _toWalletId == _walletId)) {
      setState(() => _errorMessage = 'Select a different destination wallet for transfer');
      return;
    }

    await widget.onSave(
      type: _type,
      amountMinor: amountMinor,
      category: _type == 'Transfer' ? 'Transfer' : _category,
      walletId: _walletId,
      toWalletId: _type == 'Transfer' ? _toWalletId : null,
      transactionTime: _transactionDate.millisecondsSinceEpoch,
      note: _noteController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallets.firstWhere(
      (w) => w.id == _walletId,
      orElse: () => widget.wallets.first,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Type Selector: [Expense | Income | Transfer]
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.appSurface2,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                _buildTypeBtn('Expense', 'Expense'),
                _buildTypeBtn('Income', 'Income'),
                _buildTypeBtn('Transfer', 'Transfer'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Amount Field
          Text(
            'Amount (${wallet.currency})',
            style: AppTypography.captionMuted.copyWith(color: context.appMuted),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: context.appText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.appSurface2,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              hintText: '0.00',
              hintStyle: TextStyle(
                color: context.appMuted.withValues(alpha: 0.5),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Category (hidden for transfers)
          if (_type != 'Transfer') ...[
            Text(
              'Category',
              style:
                  AppTypography.captionMuted.copyWith(color: context.appMuted),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: context.appSurface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  dropdownColor: context.appSurface,
                  isExpanded: true,
                  items: AppColors.categories.keys.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.categories[cat],
                            ),
                          ),
                          Text(cat, style: TextStyle(color: context.appText)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Wallet Selector
          Text(
            _type == 'Transfer' ? 'From Wallet' : 'Wallet',
            style: AppTypography.captionMuted.copyWith(color: context.appMuted),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: context.appSurface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _walletId,
                dropdownColor: context.appSurface,
                isExpanded: true,
                items: widget.wallets.map((w) {
                  return DropdownMenuItem(
                    value: w.id,
                    child: Text(w.name, style: TextStyle(color: context.appText)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _walletId = val);
                },
              ),
            ),
          ),

          // If Transfer -> Destination Wallet
          if (_type == 'Transfer') ...[
            const SizedBox(height: 14),
            Text(
              'To Wallet',
              style: AppTypography.captionMuted.copyWith(color: context.appMuted),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: context.appSurface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _toWalletId ?? (widget.wallets.length > 1 ? widget.wallets.last.id : widget.wallets.first.id),
                  dropdownColor: context.appSurface,
                  isExpanded: true,
                  items: widget.wallets.map((w) {
                    return DropdownMenuItem(
                      value: w.id,
                      child: Text(w.name, style: TextStyle(color: context.appText)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _toWalletId = val);
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Date Picker
          Text(
            'Date',
            style: AppTypography.captionMuted.copyWith(color: context.appMuted),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _transactionDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setState(() => _transactionDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.appSurface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd').format(_transactionDate),
                    style: TextStyle(color: context.appText),
                  ),
                  Icon(Icons.calendar_today, size: 18, color: context.appMuted),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Description / Note
          Text(
            'Description',
            style: AppTypography.captionMuted.copyWith(color: context.appMuted),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            style: TextStyle(color: context.appText),
            decoration: InputDecoration(
              hintText: 'e.g. Groceries',
              hintStyle: TextStyle(
                color: context.appMuted.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: context.appSurface2,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],

          const SizedBox(height: 20),

          // Action Buttons: Save & optional Move to Trash
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.isDarkMode
                  ? AppColors.darkText
                  : AppColors.lightText,
              foregroundColor: context.isDarkMode
                  ? AppColors.darkBg
                  : AppColors.lightBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: _onSavePressed,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          if (widget.onDelete != null) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appSurface2,
                foregroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete!();
              },
              child: const Text(
                'Move to Trash',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBtn(String typeKey, String label) {
    final isSelected = _type == typeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = typeKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? context.appSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? context.appText : context.appMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
