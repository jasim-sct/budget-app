import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/financial_calculation_engine.dart';
import '../../../core/services/financial_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../domain/transaction_model.dart';

/// Modal Bottom Sheet displaying full transaction details, formatted timestamps, and Audit Version History.
class TransactionDetailModal extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback? onUpdateRequested;

  const TransactionDetailModal({
    super.key,
    required this.transaction,
    this.onUpdateRequested,
  });

  @override
  State<TransactionDetailModal> createState() => _TransactionDetailModalState();
}

class _TransactionDetailModalState extends State<TransactionDetailModal> {
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoadingLogs = true;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    if (widget.transaction.id == null) {
      setState(() => _isLoadingLogs = false);
      return;
    }
    final logs = await DatabaseHelper.instance.getAuditLogs('transaction', '${widget.transaction.id}');
    if (mounted) {
      setState(() {
        _auditLogs = logs;
        _isLoadingLogs = false;
      });
    }
  }

  Future<void> _deleteTransaction() async {
    if (widget.transaction.id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          title: Text('Delete Ledger Entry?', style: AppTypography.titleLarge(isDark)),
          content: Text(
            'Are you sure you want to delete "${widget.transaction.title}" (${AppFormatters.currency(widget.transaction.amount)})? This action cannot be undone.',
            style: AppTypography.bodyMedium(isDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expenseRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && widget.transaction.id != null) {
      await DatabaseHelper.instance.deleteTransaction(widget.transaction.id!);
      FinancialSyncService.instance.notifyMutation();
      await FinancialCalculationEngine.instance.recalculate();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ledger entry deleted successfully'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = widget.transaction;
    final isIncome = tx.type == TransactionType.income;

    return GlassBottomSheet(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (isIncome ? AppColors.incomeGreen : AppColors.expenseRed).withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderXs,
                      ),
                      child: Icon(
                        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Ledger Entry Details',
                      style: AppTypography.headline(isDark),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Amount & Title Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: AppTypography.titleLarge(isDark).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'}${AppFormatters.currency(tx.amount)}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
                        ),
                      ),
                      AppChip(
                        label: isIncome ? 'INCOME' : 'EXPENSE',
                        isSelected: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primaryBlue),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            AppFormatters.dateTimeShortFromMs(tx.dateMilliseconds),
                            style: AppTypography.caption(isDark).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppColors.primaryBlue),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            tx.accountName ?? 'Cash Wallet',
                            style: AppTypography.caption(isDark).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Category Info
            Row(
              children: [
                Text('CATEGORY: ', style: AppTypography.sectionLabel(isDark)),
                const SizedBox(width: AppSpacing.xs),
                AppChip(
                  label: tx.category,
                  isSelected: true,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Financial Decision Context Card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FINANCIAL DECISION IMPACT', style: AppTypography.sectionLabel(isDark)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isIncome ? Icons.account_balance_wallet_outlined : Icons.account_tree_outlined,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isIncome
                              ? 'Credited ${AppFormatters.currency(tx.amount)} directly to ${tx.accountName ?? "Cash Wallet"}. Boosts net cash flow.'
                              : 'Debited ${AppFormatters.currency(tx.amount)} from ${tx.accountName ?? "Cash Wallet"} under the "${tx.category}" envelope.',
                          style: AppTypography.bodyMedium(isDark).copyWith(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Audit & Version History Timeline
            Text('AUDIT & VERSION HISTORY', style: AppTypography.sectionLabel(isDark)),
            const SizedBox(height: AppSpacing.xs),

            if (_isLoadingLogs)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
              )
            else if (_auditLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  'No historical edits recorded for this ledger entry.',
                  style: AppTypography.caption(isDark),
                ),
              )
            else
              Column(
                children: _auditLogs.map((log) {
                  final action = (log['action'] as String? ?? 'created').toUpperCase();
                  final ts = (log['timestamp'] as int? ?? 0);
                  final oldValue = log['old_value'] as String?;
                  final newValue = log['new_value'] as String?;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: action == 'CREATED'
                                      ? AppColors.incomeGreen.withValues(alpha: 0.12)
                                      : AppColors.primaryBlue.withValues(alpha: 0.12),
                                  borderRadius: AppRadius.borderXs,
                                ),
                                child: Text(
                                  action,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: action == 'CREATED' ? AppColors.incomeGreen : AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                              Text(
                                AppFormatters.dateTimeShortFromMs(ts),
                                style: AppTypography.caption(isDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (oldValue != null && oldValue.isNotEmpty) ...[
                            Text(
                              'Previous: $oldValue',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          if (newValue != null && newValue.isNotEmpty)
                            Text(
                              'Current: $newValue',
                              style: AppTypography.titleMedium(isDark).copyWith(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: AppSpacing.lg),

            // Actions
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Delete Entry',
                    icon: Icons.delete_outline_rounded,
                    variant: AppButtonVariant.danger,
                    onPressed: _deleteTransaction,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
