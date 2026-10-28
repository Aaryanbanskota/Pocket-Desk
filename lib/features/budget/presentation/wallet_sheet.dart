import 'package:flutter/material.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_bottom_sheet.dart';
import '../data/budget_repository.dart';

class WalletSheet {
  static Future<void> show({
    required BuildContext context,
    required void Function(String name, String currency, int startingBalanceMinor) onSave,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: 'New wallet',
      child: _WalletSheetContent(onSave: onSave),
    );
  }

  static Future<void> showForAccount({
    required BuildContext context,
    required BudgetRepository budgetRepository,
    required String accountId,
    VoidCallback? onSaved,
  }) {
    return show(
      context: context,
      onSave: (name, currency, startingBalanceMinor) async {
        await budgetRepository.addWallet(
          accountId: accountId,
          name: name,
          currency: currency,
          initialBalanceMinor: startingBalanceMinor,
        );
        onSaved?.call();
      },
    );
  }
}

class _WalletSheetContent extends StatefulWidget {
  final void Function(String name, String currency, int startingBalanceMinor) onSave;

  const _WalletSheetContent({required this.onSave});

  @override
  State<_WalletSheetContent> createState() => _WalletSheetContentState();
}

class _WalletSheetContentState extends State<_WalletSheetContent> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  String _currency = 'Rs';
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Name', style: AppTypography.captionMuted.copyWith(color: context.appMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          style: TextStyle(color: context.appText),
          decoration: InputDecoration(
            hintText: 'e.g. Bank Account',
            filled: true,
            fillColor: context.appSurface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),

        Text('Currency', style: AppTypography.captionMuted.copyWith(color: context.appMuted)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: context.appSurface2, borderRadius: BorderRadius.circular(14)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _currency,
              dropdownColor: context.appSurface,
              isExpanded: true,
              items: ['Rs', '\$', '€', '£', '¥', '₹'].map((c) {
                return DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: context.appText)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _currency = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        Text('Starting balance', style: AppTypography.captionMuted.copyWith(color: context.appMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: _balanceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: context.appText),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.appSurface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
        ],
        const SizedBox(height: 20),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.isDarkMode ? AppColors.darkText : AppColors.lightText,
            foregroundColor: context.isDarkMode ? AppColors.darkBg : AppColors.lightBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              setState(() => _errorMessage = 'Enter a wallet name');
              return;
            }
            final bal = double.tryParse(_balanceController.text) ?? 0.0;
            final minor = (bal * 100).round();
            widget.onSave(name, _currency, minor);
            Navigator.of(context).pop();
          },
          child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class BudgetSheet {
  static Future<void> show({
    required BuildContext context,
    MyDayBudget? budgetToEdit,
    required void Function(String category, int monthlyLimitMinor) onSave,
    VoidCallback? onDelete,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: budgetToEdit != null ? 'Edit budget' : 'New monthly budget',
      child: _BudgetSheetContent(
        budgetToEdit: budgetToEdit,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  static Future<void> showForAccount({
    required BuildContext context,
    required BudgetRepository budgetRepository,
    required String accountId,
    MyDayBudget? budget,
    VoidCallback? onSaved,
  }) {
    return show(
      context: context,
      budgetToEdit: budget,
      onSave: (category, monthlyLimitMinor) async {
        await budgetRepository.setBudget(
          accountId: accountId,
          category: category,
          limitMinor: monthlyLimitMinor,
          existingId: budget?.id,
        );
        onSaved?.call();
      },
      onDelete: budget != null
          ? () async {
              await budgetRepository.deleteBudget(budget.id);
              onSaved?.call();
            }
          : null,
    );
  }
}

class _BudgetSheetContent extends StatefulWidget {
  final MyDayBudget? budgetToEdit;
  final void Function(String category, int monthlyLimitMinor) onSave;
  final VoidCallback? onDelete;

  const _BudgetSheetContent({
    this.budgetToEdit,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_BudgetSheetContent> createState() => _BudgetSheetContentState();
}

class _BudgetSheetContentState extends State<_BudgetSheetContent> {
  late String _category;
  late TextEditingController _limitController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _category = widget.budgetToEdit?.category ?? 'Food';
    _limitController = TextEditingController(
      text: widget.budgetToEdit != null
          ? (widget.budgetToEdit!.monthlyLimit / 100.0).toStringAsFixed(0)
          : '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Category', style: AppTypography.captionMuted.copyWith(color: context.appMuted)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: context.appSurface2, borderRadius: BorderRadius.circular(14)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              dropdownColor: context.appSurface,
              isExpanded: true,
              items: AppColors.categories.keys.map((c) {
                return DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: context.appText)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        Text('Monthly limit', style: AppTypography.captionMuted.copyWith(color: context.appMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: _limitController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: context.appText),
          decoration: InputDecoration(
            hintText: 'e.g. 5000',
            filled: true,
            fillColor: context.appSurface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
        ],
        const SizedBox(height: 20),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.isDarkMode ? AppColors.darkText : AppColors.lightText,
            foregroundColor: context.isDarkMode ? AppColors.darkBg : AppColors.lightBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onPressed: () {
            final val = double.tryParse(_limitController.text);
            if (val == null || val <= 0) {
              setState(() => _errorMessage = 'Enter a valid limit');
              return;
            }
            final minor = (val * 100).round();
            widget.onSave(_category, minor);
            Navigator.of(context).pop();
          },
          child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        if (widget.onDelete != null) ...[
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appSurface2,
              foregroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete!();
            },
            child: const Text('Delete Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}
