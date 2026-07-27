import 'package:flutter/material.dart';
import '../../../../core/services/financial_calculation_engine.dart';
import '../../../../core/services/financial_metrics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/animated_number_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../application/accounts_controller.dart';
import '../../domain/models/account_model.dart';
import '../modals/add_account_modal.dart';
import '../modals/account_detail_modal.dart';

/// Money Screen — "Where does my money live?"
/// Calm, clear view of accounts and net worth.
class AccountsScreen extends StatefulWidget {
  final AccountsController controller;
  final ScrollController? scrollController;

  const AccountsScreen({
    super.key,
    required this.controller,
    this.scrollController,
  });

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    widget.controller.loadAccounts();
    FinancialCalculationEngine.instance.recalculate();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _showAddAccountModal() {
    AddAccountModal.show(
      context,
      onSaved: (acc) async {
        await widget.controller.loadAccounts();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money'),
      ),
      body: ValueListenableBuilder<FinancialMetrics>(
        valueListenable: FinancialCalculationEngine.instance.metricsNotifier,
        builder: (context, metrics, _) {
          return ListenableBuilder(
            listenable: widget.controller.stateNotifier,
            builder: (context, _) {
              final state = widget.controller.stateNotifier.value;

              if (state.isLoading && state.accounts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: AppColors.primaryBlue,
                  ),
                );
              }

              return ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.sm,
                ),
                children: [
                  // Net Worth Hero
                  _NetWorthHero(
                    netWorth: metrics.netWorth,
                    totalAssets: metrics.totalAssets,
                    totalLiabilities: metrics.totalLiabilities,
                    isDark: isDark,
                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // Account list header
                  Text(
                    'ACCOUNTS',
                    style: AppTypography.insightLabel(isDark),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (state.accounts.isEmpty)
                    EmptyStateWidget(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No accounts yet',
                      description: 'Add your bank accounts or cash wallets to track your money.',
                      actionLabel: 'Add Account',
                      onActionTap: _showAddAccountModal,
                    )
                  else
                    ...state.accounts.map((acc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _AccountCard(
                          account: acc,
                          isDark: isDark,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => AccountDetailModal(
                                account: acc,
                                onChanged: () => widget.controller.loadAccounts(),
                              ),
                            );
                          },
                        ),
                      );
                    }),

                  const SizedBox(height: AppSpacing.xl),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Net worth hero section — calm, value-dominant.
class _NetWorthHero extends StatelessWidget {
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final bool isDark;

  const _NetWorthHero({
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net worth',
            style: AppTypography.insightLabel(isDark).copyWith(
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedNumberText(
              value: netWorth,
              style: AppTypography.financialHero(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _NetWorthMetric(
                  label: 'Assets',
                  value: AppFormatters.currency(totalAssets),
                  color: AppColors.incomeGreen,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              Expanded(
                child: _NetWorthMetric(
                  label: 'Liabilities',
                  value: AppFormatters.currency(totalLiabilities),
                  color: AppColors.expenseRed,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetWorthMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _NetWorthMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppTypography.caption(isDark).copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

/// Clean account card — icon, name, type, balance.
class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final bool isDark;
  final VoidCallback? onTap;

  const _AccountCard({
    required this.account,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(account.colorValue).withValues(alpha: 0.12),
              borderRadius: AppRadius.borderSm,
            ),
            child: Icon(
              account.type == AccountType.cash
                  ? Icons.wallet_rounded
                  : Icons.account_balance_rounded,
              color: Color(account.colorValue),
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium(isDark).copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  account.type == AccountType.cash ? 'Cash wallet' : 'Bank account',
                  style: AppTypography.caption(isDark).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppFormatters.currency(account.balance),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
