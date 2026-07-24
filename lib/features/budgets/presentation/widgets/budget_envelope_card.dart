import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/scan_first_components.dart';
import '../../data/datasources/budget_dao.dart';
import '../widgets/budget_overspend_recovery_sheet.dart';
import '../widgets/remaining_budget_transfer_sheet.dart';

/// Scan-First & Mobile-First Category Envelope Card.
/// Fully responsive down to 320px minimum viewport.
class BudgetEnvelopeCard extends StatefulWidget {
  final BudgetSpentSummary summary;
  final VoidCallback? onActionCompleted;

  const BudgetEnvelopeCard({
    super.key,
    required this.summary,
    this.onActionCompleted,
  });

  @override
  State<BudgetEnvelopeCard> createState() => _BudgetEnvelopeCardState();
}

class _BudgetEnvelopeCardState extends State<BudgetEnvelopeCard> {
  bool _isExplanationExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = widget.summary.metrics;
    final statusColor = metrics.status.primaryColor;
    final isOverspent = metrics.remaining < 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP ROW: Category Title, Status Badge & Days Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Icon(Icons.pie_chart_rounded, color: statusColor, size: 16),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        widget.summary.budget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    AppStatusBadge(
                      label: metrics.status.label,
                      color: statusColor,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${metrics.remainingDays}d left',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // 2. PRIMARY HIGHLIGHTED VALUE: Remaining Budget (FittedBox for 320px)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  AppFormatters.currency(metrics.remaining.abs()),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isOverspent ? AppColors.expenseRed : AppColors.incomeGreen,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOverspent ? 'OVERSPENT' : 'REMAINING',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isOverspent ? AppColors.expenseRed : AppColors.incomeGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // 3. PROGRESS BAR
          ClipRRect(
            borderRadius: AppRadius.borderPill,
            child: LinearProgressIndicator(
              value: (metrics.progressPercentage / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
              color: statusColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // 4. SCAN-FIRST KEYWORD METRIC CHIPS
          Row(
            children: [
              Expanded(
                child: AppKeywordMetricTile(
                  keyword: 'TODAY\'S SAFE LIMIT',
                  value: '${AppFormatters.currency(metrics.dailyTarget)}/day',
                  color: isOverspent ? AppColors.expenseRed : AppColors.primaryBlue,
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppKeywordMetricTile(
                  keyword: 'SPENT / BUDGET',
                  value: '${AppFormatters.currency(metrics.spent)} / ${AppFormatters.currency(metrics.allocation)}',
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  icon: Icons.pie_chart_outline_rounded,
                ),
              ),
            ],
          ),

          // 5. PROGRESSIVE DISCLOSURE & ACTION TOOLBAR
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _isExplanationExpanded = !_isExplanationExpanded);
                },
                child: Row(
                  children: [
                    Icon(
                      _isExplanationExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _isExplanationExpanded ? 'Hide' : 'Details',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (metrics.canTransferRemaining)
                      GestureDetector(
                        onTap: () {
                          RemainingBudgetTransferSheet.show(
                            context,
                            metrics: metrics,
                            onTransferCompleted: () {
                              if (widget.onActionCompleted != null) widget.onActionCompleted!();
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.incomeGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.incomeGreen.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.swap_horiz_rounded, size: 13, color: AppColors.incomeGreen),
                              SizedBox(width: 3),
                              Text(
                                'TRANSFER',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.incomeGreen),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (metrics.needsRecovery) ...[
                      if (metrics.canTransferRemaining) const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          BudgetOverspendRecoverySheet.show(
                            context,
                            metrics: metrics,
                            onRecoveryCompleted: () {
                              if (widget.onActionCompleted != null) widget.onActionCompleted!();
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.expenseRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.expenseRed.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.shield_outlined, size: 13, color: AppColors.expenseRed),
                              SizedBox(width: 3),
                              Text(
                                'RECOVER',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.expenseRed),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // EXPANDABLE DETAILS
          if (_isExplanationExpanded) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENVELOPE AUDIT & BREAKDOWN',
                    style: AppTypography.sectionLabel(isDark).copyWith(fontSize: 8.5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Period Allocation:', style: AppTypography.caption(isDark)),
                      Text(AppFormatters.currency(metrics.allocation), style: AppTypography.titleMedium(isDark)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Outflow:', style: AppTypography.caption(isDark)),
                      Text(AppFormatters.currency(metrics.spent), style: AppTypography.titleMedium(isDark)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Used Percentage:', style: AppTypography.caption(isDark)),
                      Text('${metrics.progressPercentage.toStringAsFixed(1)}%', style: AppTypography.titleMedium(isDark)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
