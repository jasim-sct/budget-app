import 'package:flutter/material.dart';
import '../services/global_filter_controller.dart';
import '../services/global_filter_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'glass/glass_filter_modal.dart';

/// Global Filter Bar with search input and filter badge.
class GlobalFilterBar extends StatefulWidget {
  const GlobalFilterBar({super.key});

  @override
  State<GlobalFilterBar> createState() => _GlobalFilterBarState();
}

class _GlobalFilterBarState extends State<GlobalFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalFilterController _controller = GlobalFilterController.instance;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GlassFilterModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<GlobalFilterState>(
      valueListenable: _controller.filterNotifier,
      builder: (context, filter, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
            borderRadius: AppRadius.borderSm,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => _controller.setSearchQuery(val),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search merchant, category, notes...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty || filter.isFilterActive)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    _controller.resetFilters();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              InkWell(
                onTap: _openFilterModal,
                borderRadius: AppRadius.borderSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: filter.isFilterActive
                        ? AppColors.primaryBlue.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary),
                    borderRadius: AppRadius.borderSm,
                    border: filter.isFilterActive
                        ? Border.all(color: AppColors.primaryBlue, width: 1)
                        : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: filter.isFilterActive ? AppColors.primaryBlue : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      if (filter.activeFilterCount > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: AppRadius.borderXs,
                          ),
                          child: Text(
                            '${filter.activeFilterCount}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
