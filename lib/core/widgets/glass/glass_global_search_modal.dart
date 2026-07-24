import 'package:flutter/material.dart';
import '../../services/global_search_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'glass_card.dart';
import 'glass_chip.dart';
import 'glass_input.dart';

class GlassGlobalSearchModal extends StatefulWidget {
  final Function(SearchResultItem item)? onItemSelect;

  const GlassGlobalSearchModal({
    super.key,
    this.onItemSelect,
  });

  static Future<T?> show<T>(BuildContext context, {Function(SearchResultItem item)? onItemSelect}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassGlobalSearchModal(onItemSelect: onItemSelect),
    );
  }

  @override
  State<GlassGlobalSearchModal> createState() => _GlassGlobalSearchModalState();
}

class _GlassGlobalSearchModalState extends State<GlassGlobalSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<SearchResultItem> _results = [];
  bool _isLoading = false;
  SearchEntityType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _performSearch('');
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    final items = await GlobalSearchService.instance.search(query);
    if (!mounted) return;
    setState(() {
      _results = items;
      _isLoading = false;
    });
  }

  List<SearchResultItem> get _filteredResults {
    if (_selectedFilter == null) return _results;
    return _results.where((item) => item.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + viewInsets,
      padding: EdgeInsets.only(bottom: viewInsets),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xEC0F172A) : const Color(0xFDF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GlassInput(
              controller: _searchController,
              focusNode: _focusNode,
              hint: 'Search transactions, budgets, accounts, actions...',
              prefixIcon: Icons.search_rounded,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              onChanged: (val) => _performSearch(val),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                GlassChip(
                  label: 'All',
                  isSelected: _selectedFilter == null,
                  onTap: () => setState(() => _selectedFilter = null),
                ),
                const SizedBox(width: 6),
                GlassChip(
                  label: 'Actions',
                  isSelected: _selectedFilter == SearchEntityType.action,
                  onTap: () => setState(() => _selectedFilter = SearchEntityType.action),
                ),
                const SizedBox(width: 6),
                GlassChip(
                  label: 'Transactions',
                  isSelected: _selectedFilter == SearchEntityType.transaction,
                  onTap: () => setState(() => _selectedFilter = SearchEntityType.transaction),
                ),
                const SizedBox(width: 6),
                GlassChip(
                  label: 'Accounts',
                  isSelected: _selectedFilter == SearchEntityType.account,
                  onTap: () => setState(() => _selectedFilter = SearchEntityType.account),
                ),
                const SizedBox(width: 6),
                GlassChip(
                  label: 'Budgets',
                  isSelected: _selectedFilter == SearchEntityType.budget,
                  onTap: () => setState(() => _selectedFilter = SearchEntityType.budget),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue))
                : _filteredResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'No matching results found',
                              style: AppTypography.titleMedium(isDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try searching with a different term or entity type.',
                              style: AppTypography.caption(isDark),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        itemCount: _filteredResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final item = _filteredResults[index];
                          return GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            onTap: () {
                              Navigator.pop(context, item);
                              if (widget.onItemSelect != null) {
                                widget.onItemSelect!(item);
                              }
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: item.iconColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(item.icon, color: item.iconColor, size: 20),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle,
                                        style: AppTypography.caption(isDark),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
