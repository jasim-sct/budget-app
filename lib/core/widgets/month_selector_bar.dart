import 'package:flutter/material.dart';
import '../state/month_selector_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';
import 'glass/glass_container.dart';

/// Glassmorphic Month Selector Header Bar.
/// Embedded across Dashboard, Transactions, Budgets, Analytics, and Reports.
class MonthSelectorBar extends StatelessWidget {
  const MonthSelectorBar({super.key});

  Future<void> _showMonthPicker(BuildContext context, DateTime current) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: AppColors.primaryEmerald)
                : const ColorScheme.light(primary: AppColors.primaryEmerald),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      MonthSelectorController.instance.selectMonth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<DateTime>(
      valueListenable: MonthSelectorController.instance,
      builder: (context, selectedDate, _) {
        final monthStr = AppFormatters.monthYear(selectedDate);
        final isCurrentMonth = MonthSelectorController.instance.isCurrentMonth;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            borderRadius: AppRadius.borderPill,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                  onPressed: () => MonthSelectorController.instance.previousMonth(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
                GestureDetector(
                  onTap: () => _showMonthPicker(context, selectedDate),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primaryEmerald),
                      const SizedBox(width: 8),
                      Text(
                        monthStr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (isCurrentMonth) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                            borderRadius: AppRadius.borderPill,
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                  onPressed: () => MonthSelectorController.instance.nextMonth(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
