import 'package:flutter/material.dart';
import '../services/global_filter_controller.dart';
import '../services/global_filter_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'glass/glass_card.dart';
import 'glass/glass_filter_modal.dart';

/// Floating VisionOS Glass Global Filter Bar.
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
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.primaryEmerald, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => _controller.setSearchQuery(val),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search merchant, category, notes, tags...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty || filter.isFilterActive)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _controller.resetFilters();
                  },
                ),
              GestureDetector(
                onTap: _openFilterModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: filter.isFilterActive
                        ? AppColors.primaryEmerald.withValues(alpha: 0.25)
                        : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary),
                    borderRadius: AppRadius.borderPill,
                    border: filter.isFilterActive
                        ? Border.all(color: AppColors.primaryEmerald, width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: filter.isFilterActive ? AppColors.primaryEmerald : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      if (filter.activeFilterCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryEmerald,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${filter.activeFilterCount}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
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
