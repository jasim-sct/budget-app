import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/transaction_detail_modal.dart';
import '../../../transactions/presentation/widgets/transaction_item_tile.dart';
import '../../domain/models/account_model.dart';

/// Modal Bottom Sheet displaying Account Analytics, linked ledger transactions, and balance history.
class AccountDetailModal extends StatefulWidget {
  final AccountModel account;

  const AccountDetailModal({
    super.key,
    required this.account,
  });

  @override
  State<AccountDetailModal> createState() => _AccountDetailModalState();
}

class _AccountDetailModalState extends State<AccountDetailModal> {
  Map<String, dynamic> _analytics = {};
  List<TransactionModel> _linkedTransactions = [];
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final analyticsData = await db.getAccountAnalytics(widget.account.id);
    final rawTxList = await db.getTransactionsForAccount(widget.account.id);
    final txList = rawTxList.map((m) => TransactionModel.fromMap(m)).toList();
    final logs = await db.getAuditLogs('account', widget.account.id);

    if (mounted) {
      setState(() {
        _analytics = analyticsData;
        _linkedTransactions = txList;
        _auditLogs = logs;
        _isLoading = false;
      });
    }
  }

  String _getAccountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 'BANK ACCOUNT';
      case AccountType.cash:
        return 'CASH WALLET';
      default:
        return type.name.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final acc = widget.account;

    final double totalIncome = (_analytics['income'] as num?)?.toDouble() ?? 0.0;
    final double totalExpense = (_analytics['expense'] as num?)?.toDouble() ?? 0.0;
    final double netFlow = (_analytics['net'] as num?)?.toDouble() ?? 0.0;
    final int txCount = (_analytics['count'] as num?)?.toInt() ?? 0;

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
                        color: AppColors.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderXs,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryBlue, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Wallet Analytics & History',
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

            // Account Header Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        acc.name,
                        style: AppTypography.titleLarge(isDark).copyWith(fontSize: 18),
                      ),
                      AppChip(
                        label: _getAccountTypeLabel(acc.type),
                        isSelected: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppFormatters.currency(acc.balance),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: acc.balance < 0 ? AppColors.expenseRed : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Account Specific Analytics Card
            Text('WALLET ANALYTICS METRICS', style: AppTypography.sectionLabel(isDark)),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, color: AppColors.incomeGreen, size: 14),
                          const SizedBox(width: AppSpacing.xs),
                          Text('Total Inflow:', style: AppTypography.caption(isDark)),
                        ],
                      ),
                      Text(
                        AppFormatters.currency(totalIncome),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.incomeGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, color: AppColors.expenseRed, size: 14),
                          const SizedBox(width: AppSpacing.xs),
                          Text('Total Outflow:', style: AppTypography.caption(isDark)),
                        ],
                      ),
                      Text(
                        AppFormatters.currency(totalExpense),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.expenseRed),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Cash Flow:', style: AppTypography.titleMedium(isDark)),
                      Text(
                        AppFormatters.currency(netFlow),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: netFlow >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Transactions:', style: AppTypography.caption(isDark)),
                      Text('$txCount entries', style: AppTypography.caption(isDark).copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Linked Ledger History
            Text('LINKED LEDGER TRANSACTIONS', style: AppTypography.sectionLabel(isDark)),
            const SizedBox(height: AppSpacing.xs),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
              )
            else if (_linkedTransactions.isEmpty)
              const EmptyStateWidget(
                icon: Icons.receipt_long_outlined,
                title: 'No Linked Transactions',
                description: 'No transactions have been logged under this account yet.',
              )
            else
              Column(
                children: _linkedTransactions.map<Widget>((tx) {
                  return TransactionItemTile(
                    transaction: tx,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => TransactionDetailModal(
                          transaction: tx,
                          onUpdateRequested: _loadData,
                        ),
                      ).then((_) => _loadData());
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: AppSpacing.lg),

            // Account Activity Audit Logs (if available)
            if (_auditLogs.isNotEmpty) ...[
              Text('BALANCE UPDATE HISTORY', style: AppTypography.sectionLabel(isDark)),
              const SizedBox(height: AppSpacing.xs),
              Column(
                children: _auditLogs.map<Widget>((log) {
                  final action = (log['action'] as String? ?? 'created').toUpperCase();
                  final ts = (log['timestamp'] as int? ?? 0);
                  final newValue = log['new_value'] as String?;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(action, style: AppTypography.labelSmall(isDark)),
                              if (newValue != null) Text(newValue, style: AppTypography.caption(isDark)),
                            ],
                          ),
                          Text(AppFormatters.dateTimeShortFromMs(ts), style: AppTypography.caption(isDark)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
