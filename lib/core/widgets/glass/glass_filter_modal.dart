import 'package:flutter/material.dart';
import '../../../features/transactions/domain/transaction_model.dart';
import '../../services/global_filter_controller.dart';
import '../../services/global_filter_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../app_button.dart';
import '../app_chip.dart';
import 'glass_bottom_sheet.dart';

/// Global Filter Modal Sheet.
class GlassFilterModal extends StatefulWidget {
  const GlassFilterModal({super.key});

  @override
  State<GlassFilterModal> createState() => _GlassFilterModalState();
}

class _GlassFilterModalState extends State<GlassFilterModal> {
  final GlobalFilterController _controller = GlobalFilterController.instance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<GlobalFilterState>(
      valueListenable: _controller.filterNotifier,
      builder: (context, filter, _) {
        return GlassBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Global Filter Engine',
                        style: AppTypography.headline(isDark),
                      ),
                    ],
                  ),
                  if (filter.isFilterActive)
                    TextButton(
                      onPressed: () => _controller.resetFilters(),
                      child: const Text('Reset All', style: TextStyle(color: AppColors.expenseRed, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Time Range Selector
              Text('TIME RANGE', style: AppTypography.sectionLabel(isDark)),
              const SizedBox(height: AppSpacing.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTimePresetChip('This Month', TimeRangePreset.thisMonth, filter),
                    _buildTimePresetChip('Last 30 Days', TimeRangePreset.last30Days, filter),
                    _buildTimePresetChip('Last 7 Days', TimeRangePreset.last7Days, filter),
                    _buildTimePresetChip('Today', TimeRangePreset.today, filter),
                    _buildTimePresetChip('All Time', TimeRangePreset.allTime, filter),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Transaction Types Multi-Select
              Text('TRANSACTION TYPE', style: AppTypography.sectionLabel(isDark)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(child: _buildTypeChip('Expense', TransactionType.expense, filter)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: _buildTypeChip('Income', TransactionType.income, filter)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              AppButton(
                label: 'Apply Filters (${filter.activeFilterCount} Active)',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimePresetChip(String label, TimeRangePreset preset, GlobalFilterState filter) {
    final isSelected = filter.timeRangePreset == preset;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: AppChip(
        label: label,
        isSelected: isSelected,
        onTap: () => _controller.updateTimeRange(preset),
      ),
    );
  }

  Widget _buildTypeChip(String label, TransactionType type, GlobalFilterState filter) {
    final isSelected = filter.transactionTypes.contains(type);
    return AppChip(
      label: label,
      isSelected: isSelected,
      onTap: () => _controller.toggleTransactionType(type),
    );
  }
}
