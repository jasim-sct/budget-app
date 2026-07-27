import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'feedback_toast.dart';

class AppTableColumn<T> {
  final String title;
  final Widget Function(T item) builder;
  final Comparable Function(T item)? sortKey;
  final double flex;

  const AppTableColumn({
    required this.title,
    required this.builder,
    this.sortKey,
    this.flex = 1.0,
  });
}

class AppDataTable<T> extends StatefulWidget {
  final List<T> items;
  final List<AppTableColumn<T>> columns;
  final String title;
  final bool enableSelection;
  final void Function(List<T> selectedItems)? onSelectionChanged;
  final void Function(T item)? onItemTap;
  final int rowsPerPage;

  const AppDataTable({
    super.key,
    required this.items,
    required this.columns,
    this.title = '',
    this.enableSelection = false,
    this.onSelectionChanged,
    this.onItemTap,
    this.rowsPerPage = 10,
  });

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T> extends State<AppDataTable<T>> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final Set<T> _selectedItems = {};
  int _currentPage = 0;

  void _onSort(int columnIndex) {
    final col = widget.columns[columnIndex];
    if (col.sortKey == null) return;

    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
    });
  }

  void _toggleSelectAll(List<T> pageItems) {
    setState(() {
      if (_selectedItems.containsAll(pageItems)) {
        _selectedItems.removeAll(pageItems);
      } else {
        _selectedItems.addAll(pageItems);
      }
    });
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_selectedItems.toList());
    }
  }

  void _toggleSelectItem(T item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_selectedItems.toList());
    }
  }

  void _copySelectedToClipboard(BuildContext context) {
    if (_selectedItems.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _selectedItems.toString()));
    FeedbackToast.show(context, message: '${_selectedItems.length} rows copied to clipboard.', isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<T> displayed = List.from(widget.items);

    if (_sortColumnIndex != null) {
      final col = widget.columns[_sortColumnIndex!];
      if (col.sortKey != null) {
        displayed.sort((a, b) {
          final compA = col.sortKey!(a);
          final compB = col.sortKey!(b);
          final result = compA.compareTo(compB);
          return _sortAscending ? result : -result;
        });
      }
    }

    final totalPages = (displayed.length / widget.rowsPerPage).ceil().clamp(1, 9999);
    _currentPage = _currentPage.clamp(0, totalPages - 1);
    final startIndex = _currentPage * widget.rowsPerPage;
    final pageItems = displayed.skip(startIndex).take(widget.rowsPerPage).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title.isNotEmpty || widget.enableSelection)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.title.isNotEmpty)
                    Text(widget.title, style: AppTypography.headline(isDark).copyWith(fontSize: 15)),
                  if (widget.enableSelection && _selectedItems.isNotEmpty)
                    Row(
                      children: [
                        Text(
                          '${_selectedItems.length} selected',
                          style: AppTypography.caption(isDark).copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          onPressed: () => _copySelectedToClipboard(context),
                          tooltip: 'Copy data',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          // Sticky Header Row
          Container(
            color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                if (widget.enableSelection)
                  Checkbox(
                    value: pageItems.isNotEmpty && _selectedItems.containsAll(pageItems),
                    onChanged: (_) => _toggleSelectAll(pageItems),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ...widget.columns.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final col = entry.value;
                  final isSorted = _sortColumnIndex == idx;

                  return Expanded(
                    flex: (col.flex * 10).toInt(),
                    child: InkWell(
                      onTap: col.sortKey != null ? () => _onSort(idx) : null,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              col.title.toUpperCase(),
                              style: AppTypography.sectionLabel(isDark).copyWith(fontSize: 11),
                            ),
                          ),
                          if (col.sortKey != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              isSorted
                                  ? (_sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                                  : Icons.unfold_more_rounded,
                              size: 14,
                              color: isSorted ? AppColors.primaryBlue : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          // Data Rows
          if (pageItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text('No records found', style: AppTypography.caption(isDark)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pageItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = pageItems[index];
                final isSelected = _selectedItems.contains(item);

                return InkWell(
                  onTap: widget.onItemTap != null ? () => widget.onItemTap!(item) : null,
                  child: Container(
                    color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.08) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        if (widget.enableSelection)
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelectItem(item),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ...widget.columns.map((col) {
                          return Expanded(
                            flex: (col.flex * 10).toInt(),
                            child: col.builder(item),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          // Pagination Footer Bar
          if (displayed.length > widget.rowsPerPage)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${startIndex + 1} - ${(startIndex + widget.rowsPerPage).clamp(0, displayed.length)} of ${displayed.length}',
                    style: AppTypography.caption(isDark),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                      ),
                      Text(
                        'Page ${_currentPage + 1} of $totalPages',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
