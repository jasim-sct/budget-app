import 'package:flutter/material.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/financial_calculation_engine.dart';
import '../../../core/services/financial_metrics.dart';
import '../../../core/services/financial_sync_service.dart';
import '../../../core/services/intent_decision_engine.dart';
import '../../../core/services/time_context_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_number_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/calculation_explanation_modal.dart';
import '../../../core/widgets/intent_card.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/widgets/transaction_item_tile.dart';

/// Intent-Driven Dashboard — answers "How am I doing today?"
/// Single hero metric + insights + month snapshot + recent activity.
class DashboardScreen extends StatefulWidget {
  final TransactionRepository repository;
  final VoidCallback? onNavigateToLedger;
  final VoidCallback? onNavigateToWallets;
  final VoidCallback? onNavigateToBudgets;
  final VoidCallback? onNavigateToAnalytics;

  const DashboardScreen({
    super.key,
    required this.repository,
    this.onNavigateToLedger,
    this.onNavigateToWallets,
    this.onNavigateToBudgets,
    this.onNavigateToAnalytics,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hideBalance = false;
  bool _isEnvelopeExpanded = false;
  IntentDecisionState? _intentState;
  late TimeContextState _timeContext;

  @override
  void initState() {
    super.initState();
    _timeContext = TimeContextEngine.getCurrentContext();
    _loadIntentState();

    FinancialSyncService.instance.addListener(_onFinancialMutation);
    FinancialCalculationEngine.instance.metricsNotifier.addListener(_onFinancialMutation);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.repository.loadInitialData();
      FinancialCalculationEngine.instance.recalculate();
    });
  }

  @override
  void dispose() {
    FinancialSyncService.instance.removeListener(_onFinancialMutation);
    FinancialCalculationEngine.instance.metricsNotifier.removeListener(_onFinancialMutation);
    super.dispose();
  }

  void _onFinancialMutation() {
    _loadIntentState();
  }

  Future<void> _loadIntentState() async {
    final state = await IntentDecisionEngine.evaluateCurrentIntent();
    if (mounted) {
      setState(() {
        _intentState = state;
      });
    }
  }

  void _showCalculationExplanation() {
    final details = _intentState?.envelopeDetails ?? [];
    CalculationExplanationModal.show(
      context,
      title: 'Daily Safe Spending Calculation',
      metricValue: AppFormatters.currency(_intentState?.dailySafeSpend ?? 0.0),
      formulaDescription:
          'Today\'s safe amount = sum of fixed daily allocations (budget ÷ period days) minus today\'s actual spending. Negative means exceeded today\'s plan.',
      latexFormula: r'Safe_{today} = \sum (Budget \div Days) - Spent_{today}',
      envelopeDetails: details,
      dateRange: AppFormatters.date(DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await widget.repository.loadInitialData();
            await FinancialCalculationEngine.instance.recalculate();
            await _loadIntentState();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),

                // ── Header: Greeting + Actions ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _timeContext.greeting,
                            style: AppTypography.caption(isDark).copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Alex',
                            style: AppTypography.headline(isDark),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderIconButton(
                          icon: _hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          onTap: () => setState(() => _hideBalance = !_hideBalance),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 4),
                        _HeaderIconButton(
                          icon: Icons.settings_outlined,
                          onTap: () {
                            AppRouter.push(
                              context,
                              SettingsScreen(repository: widget.repository),
                            );
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sectionGap),

                // ── Financial Pulse Card ──
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.sectionGap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label
                      Row(
                        children: [
                          Text(
                            'Today\'s safe spend',
                            style: AppTypography.insightLabel(isDark).copyWith(
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (_intentState != null)
                            Text(
                              '${_intentState!.remainingDays} days left',
                              style: AppTypography.caption(isDark).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Hero number
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _hideBalance
                            ? Text(
                                '\$••••',
                                style: AppTypography.financialHero(isDark),
                              )
                            : AnimatedNumberText(
                                value: _intentState?.dailySafeSpend ?? 0.0,
                                style: AppTypography.financialHero(isDark),
                              ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Inline metrics: Remaining | Budget used
                      Row(
                        children: [
                          Expanded(
                            child: _InlineMetric(
                              label: 'Remaining',
                              value: _hideBalance
                                  ? '\$••••'
                                  : AppFormatters.currency(_intentState?.remainingBudget ?? 0.0),
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
                            child: _InlineMetric(
                              label: 'Days left',
                              value: '${_intentState?.remainingDays ?? 0}',
                              color: AppColors.primaryBlue,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Progressive disclosure
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _showCalculationExplanation,
                            child: Text(
                              'How is this calculated?',
                              style: AppTypography.actionText(isDark).copyWith(fontSize: 11.5),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isEnvelopeExpanded = !_isEnvelopeExpanded),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isEnvelopeExpanded ? 'Hide' : 'Envelopes',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryColor,
                                  ),
                                ),
                                Icon(
                                  _isEnvelopeExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                  size: 16,
                                  color: secondaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Expandable envelope breakdown
                      if (_isEnvelopeExpanded && _intentState != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Divider(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          height: 1,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ..._intentState!.envelopeDetails.map((detail) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detail.category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.titleMedium(isDark).copyWith(fontSize: 12.5),
                                      ),
                                      Text(
                                        '${AppFormatters.currency(detail.remaining)} left · ${detail.daysRemaining}d',
                                        style: AppTypography.caption(isDark).copyWith(fontSize: 10.5),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${AppFormatters.currency(detail.dailyLimit)}/day',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.incomeGreen,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap),

                // ── Insights ──
                if (_intentState != null && _intentState!.decisionCards.isNotEmpty) ...[
                  Text(
                    'Insights',
                    style: AppTypography.insightLabel(isDark),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._intentState!.decisionCards.map((card) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: IntentCard(
                        cardData: card,
                        onActionTap: () {
                          if (card.id.startsWith('overspend_') || card.id.startsWith('risk_')) {
                            if (widget.onNavigateToBudgets != null) widget.onNavigateToBudgets!();
                          } else {
                            if (widget.onNavigateToLedger != null) widget.onNavigateToLedger!();
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // ── Month Snapshot ──
                ValueListenableBuilder<FinancialMetrics>(
                  valueListenable: FinancialCalculationEngine.instance.metricsNotifier,
                  builder: (context, metrics, _) {
                    return AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.cardInner,
                        vertical: AppSpacing.sm + 2,
                      ),
                      child: Row(
                        children: [
                          _SnapshotMetric(
                            label: 'Income',
                            value: _hideBalance ? '••••' : AppFormatters.currency(metrics.totalIncome),
                            color: AppColors.incomeGreen,
                            isDark: isDark,
                          ),
                          _SnapshotDivider(isDark: isDark),
                          _SnapshotMetric(
                            label: 'Expense',
                            value: _hideBalance ? '••••' : AppFormatters.currency(metrics.totalExpense),
                            color: AppColors.expenseRed,
                            isDark: isDark,
                          ),
                          _SnapshotDivider(isDark: isDark),
                          _SnapshotMetric(
                            label: 'Net',
                            value: _hideBalance ? '••••' : AppFormatters.currency(metrics.netCashFlow),
                            color: metrics.netCashFlow >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.sectionGap),

                // ── Recent Activity ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent activity',
                      style: AppTypography.insightLabel(isDark),
                    ),
                    GestureDetector(
                      onTap: widget.onNavigateToLedger,
                      child: Text(
                        'See all',
                        style: AppTypography.actionText(isDark).copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                ListenableBuilder(
                  listenable: widget.repository.stateNotifier,
                  builder: (context, _) {
                    final txs = widget.repository.stateNotifier.value.transactions;
                    if (txs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(
                          child: Text(
                            'No transactions yet',
                            style: AppTypography.bodyMedium(isDark),
                          ),
                        ),
                      );
                    }
                    final recentList = txs.take(5).toList();
                    return Column(
                      children: recentList.map((tx) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: TransactionItemTile(
                            transaction: tx,
                            onTap: () {},
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                // Bottom safe spacing
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private Helper Widgets ──

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary,
          borderRadius: AppRadius.borderSm,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _InlineMetric({
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
                fontSize: 15,
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

class _SnapshotMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SnapshotMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption(isDark).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SnapshotDivider extends StatelessWidget {
  final bool isDark;
  const _SnapshotDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}
