import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import 'glass/glass_card.dart';
import 'financial_knowledge_sheet.dart';

class EnvelopeCalculationDetail {
  final String category;
  final double allocated;
  final double spent;
  final double remaining;
  final int daysRemaining;
  final double dailyLimit;

  const EnvelopeCalculationDetail({
    required this.category,
    required this.allocated,
    required this.spent,
    required this.remaining,
    required this.daysRemaining,
    required this.dailyLimit,
  });
}

class CalculationExplanationModal extends StatelessWidget {
  final String title;
  final String metricValue;
  final String formulaDescription;
  final String latexFormula;
  final List<EnvelopeCalculationDetail> envelopeDetails;
  final String dateRange;

  const CalculationExplanationModal({
    super.key,
    required this.title,
    required this.metricValue,
    required this.formulaDescription,
    required this.latexFormula,
    required this.envelopeDetails,
    required this.dateRange,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String metricValue,
    required String formulaDescription,
    required String latexFormula,
    required List<EnvelopeCalculationDetail> envelopeDetails,
    required String dateRange,
  }) {
    final sources = envelopeDetails.map((e) {
      final status = e.remaining < 0
          ? 'exceeded ${AppFormatters.currency(-e.remaining)}'
          : 'left ${AppFormatters.currency(e.remaining)}';
      return '${e.category}: plan ${AppFormatters.currency(e.dailyLimit)}/day − spent ${AppFormatters.currency(e.spent)} → $status';
    }).toList();
    if (sources.isEmpty) {
      sources.add('No active category budget envelopes configured.');
    }

    FinancialKnowledgeSheet.showForMetric(
      context,
      type: FinancialMetricType.dailySafeSpending,
      metricValue: metricValue,
      customTitle: title,
      customSources: sources,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDailySum = envelopeDetails.fold(0.0, (sum, e) => sum + e.dailyLimit);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate_outlined, color: AppColors.primaryBlue, size: 22),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      title,
                      style: AppTypography.titleLarge(isDark).copyWith(fontSize: 18),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Highlight Metric Box
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT CALCULATED VALUE',
                            style: AppTypography.sectionLabel(isDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metricValue,
                            style: AppTypography.displayLarge(isDark).copyWith(
                              fontSize: 26,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_outlined, color: AppColors.primaryBlue, size: 24),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Formula Card
                Text(
                  'MATHEMATICAL FORMULA & LOGIC',
                  style: AppTypography.sectionLabel(isDark),
                ),
                const SizedBox(height: AppSpacing.xs),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          latexFormula,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        formulaDescription,
                        style: AppTypography.caption(isDark).copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Active Envelopes Source Table
                Text(
                  'CONTRIBUTING BUDGET ENVELOPES (${envelopeDetails.length})',
                  style: AppTypography.sectionLabel(isDark),
                ),
                const SizedBox(height: AppSpacing.xs),

                if (envelopeDetails.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No active category budget envelopes configured. Create a budget envelope to generate daily safe spending limits.',
                      style: AppTypography.caption(isDark),
                    ),
                  )
                else
                  ...envelopeDetails.map((detail) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    detail.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleLarge(isDark).copyWith(fontSize: 15),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${AppFormatters.currency(detail.dailyLimit)}/day',
                                  style: AppTypography.titleLarge(isDark).copyWith(
                                    fontSize: 15,
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Remaining: ${AppFormatters.currency(detail.remaining)} (${AppFormatters.currency(detail.spent)} spent)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption(isDark),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${detail.daysRemaining}d left',
                                  style: AppTypography.caption(isDark).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Calculation: (${AppFormatters.currency(detail.remaining)} ÷ ${detail.daysRemaining} days) = ${AppFormatters.currency(detail.dailyLimit)}/day',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: AppSpacing.md),

                // Audit Metadata
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Calculation Date Range:', style: AppTypography.caption(isDark)),
                          Text(dateRange, style: AppTypography.caption(isDark).copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Daily Sum:', style: AppTypography.caption(isDark)),
                          Text(
                            AppFormatters.currency(totalDailySum),
                            style: AppTypography.caption(isDark).copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Source Integrity:', style: AppTypography.caption(isDark)),
                          Row(
                            children: const [
                              Icon(Icons.check_circle_rounded, color: AppColors.incomeGreen, size: 12),
                              SizedBox(width: 4),
                              Text('100% Budget Derived', style: TextStyle(fontSize: 11, color: AppColors.incomeGreen, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
