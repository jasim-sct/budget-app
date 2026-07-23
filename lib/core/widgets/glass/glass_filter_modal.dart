import 'package:flutter/material.dart';
import '../../../features/categories/domain/category_model.dart';
import '../../services/global_filter_controller.dart';
import '../../services/global_filter_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'glass_bottom_sheet.dart';
import 'glass_button.dart';

/// VisionOS Ultra-Premium Glass Filter Modal Sheet.
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
                      const Icon(Icons.filter_list_rounded, color: AppColors.primaryEmerald, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Global Filter & Query Engine',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (filter.isFilterActive)
                    TextButton(
                      onPressed: () => _controller.resetFilters(),
                      child: const Text('Reset All', style: TextStyle(color: AppColors.expenseRed, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Time Range Selector
              Text('TIME RANGE', style: AppTypography.labelSmall(isDark)),
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
              Text('TRANSACTION TYPE', style: AppTypography.labelSmall(isDark)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(child: _buildTypeChip('Expense', CategoryType.expense, filter)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTypeChip('Income', CategoryType.income, filter)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTypeChip('Transfer', CategoryType.transfer, filter)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              GlassButton(
                label: 'Apply Filters (${filter.activeFilterCount} Active)',
                variant: GlassButtonVariant.gradient,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimePresetChip(String label, TimeRangePreset preset, GlobalFilterState filter) {
    final isSelected = filter.timeRangePreset == preset;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(label),
        selectedColor: AppColors.primaryEmerald,
        onSelected: (_) => _controller.updateTimeRange(preset),
      ),
    );
  }

  Widget _buildTypeChip(String label, CategoryType type, GlobalFilterState filter) {
    final isSelected = filter.transactionTypes.contains(type);
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.primaryEmerald.withValues(alpha: 0.25),
      onSelected: (_) => _controller.toggleTransactionType(type),
    );
  }
}
