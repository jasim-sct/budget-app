import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../../domain/models/account_model.dart';

/// Account → account direct transfer using two ledger legs via [DatabaseHelper.createSelfTransfer].
class AccountTransferSheet extends StatefulWidget {
  final AccountModel fromAccount;
  final VoidCallback? onTransferCompleted;

  const AccountTransferSheet({
    super.key,
    required this.fromAccount,
    this.onTransferCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required AccountModel fromAccount,
    VoidCallback? onTransferCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountTransferSheet(
        fromAccount: fromAccount,
        onTransferCompleted: onTransferCompleted,
      ),
    );
  }

  @override
  State<AccountTransferSheet> createState() => _AccountTransferSheetState();
}

class _AccountTransferSheetState extends State<AccountTransferSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<AccountModel> _destinations = [];
  AccountModel? _toAccount;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final rows = await DatabaseHelper.instance.getAllAccounts();
      final accounts = rows
          .map(AccountModel.fromMap)
          .where((a) => a.id != widget.fromAccount.id)
          .toList();
      if (!mounted) return;
      setState(() {
        _destinations = accounts;
        _toAccount = accounts.isNotEmpty ? accounts.first : null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load accounts.';
        });
      }
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid transfer amount.');
      return;
    }
    if (_toAccount == null) {
      setState(() => _error = 'Select a destination account.');
      return;
    }
    if (amount > widget.fromAccount.balance) {
      setState(() => _error = 'Amount exceeds available balance.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await DatabaseHelper.instance.createSelfTransfer(
        fromAccountId: widget.fromAccount.id,
        fromAccountName: widget.fromAccount.name,
        toAccountId: _toAccount!.id,
        toAccountName: _toAccount!.name,
        amount: amount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      widget.onTransferCompleted?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transferred ${AppFormatters.currency(amount)} to ${_toAccount!.name}',
          ),
          backgroundColor: AppColors.incomeGreen,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transfer', style: AppTypography.headline(isDark)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Move money from ${widget.fromAccount.name} to another account.',
              style: AppTypography.caption(isDark),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('FROM', style: AppTypography.sectionLabel(isDark)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${widget.fromAccount.name} · ${AppFormatters.currency(widget.fromAccount.balance)}',
              style: AppTypography.titleMedium(isDark),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('TO', style: AppTypography.sectionLabel(isDark)),
            const SizedBox(height: AppSpacing.xs),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_destinations.isEmpty)
              Text(
                'Add another account to transfer between wallets.',
                style: AppTypography.caption(isDark),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _toAccount?.id,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                ),
                items: _destinations
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.name} · ${AppFormatters.currency(a.balance)}'),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  setState(() {
                    _toAccount = _destinations.firstWhere((a) => a.id == id);
                  });
                },
              ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'AMOUNT',
              controller: _amountController,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'NOTE (OPTIONAL)',
              controller: _notesController,
              hint: 'e.g. Move to savings',
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.expenseRed, fontSize: 12),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Transfer',
              icon: Icons.swap_horiz_rounded,
              isLoading: _submitting,
              onPressed: _destinations.isEmpty || _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
