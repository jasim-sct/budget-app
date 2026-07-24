import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Single item model for generic dropdowns and selectors.
class SelectOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final int? colorValue;
  final String? badgeText;
  final bool isDisabled;
  final String? group;

  const SelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.colorValue,
    this.badgeText,
    this.isDisabled = false,
    this.group,
  });
}

/// Generic Searchable Single Select Component with modal bottom sheet picker.
class SearchableSelect<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<SelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final String hint;
  final bool enabled;

  const SearchableSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint = 'Select option...',
    this.enabled = true,
  });

  void _openPicker(BuildContext context) {
    if (!enabled) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = options.where((opt) {
              final q = searchQuery.toLowerCase();
              return opt.label.toLowerCase().contains(q) ||
                  (opt.subtitle != null && opt.subtitle!.toLowerCase().contains(q));
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: AppTypography.headline(isDark)),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No matching options',
                              style: AppTypography.caption(isDark),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final opt = filtered[index];
                              final isSelected = opt.value == value;

                              return ListTile(
                                enabled: !opt.isDisabled,
                                leading: opt.icon != null
                                    ? Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: opt.colorValue != null
                                              ? Color(opt.colorValue!).withValues(alpha: 0.15)
                                              : AppColors.primaryBlue.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          opt.icon,
                                          size: 18,
                                          color: opt.colorValue != null
                                              ? Color(opt.colorValue!)
                                              : AppColors.primaryBlue,
                                        ),
                                      )
                                    : null,
                                title: Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppColors.primaryBlue : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                ),
                                subtitle: opt.subtitle != null
                                    ? Text(opt.subtitle!, style: AppTypography.caption(isDark))
                                    : null,
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue, size: 20)
                                    : null,
                                onTap: () {
                                  onChanged(opt.value);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedOpt = options.cast<SelectOption<T>?>().firstWhere(
          (opt) => opt?.value == value,
          orElse: () => null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppTypography.sectionLabel(isDark)),
          const SizedBox(height: AppSpacing.xs),
        ],
        InkWell(
          onTap: () => _openPicker(context),
          borderRadius: AppRadius.borderSm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                if (selectedOpt?.icon != null) ...[
                  Icon(
                    selectedOpt!.icon,
                    size: 18,
                    color: selectedOpt.colorValue != null ? Color(selectedOpt.colorValue!) : AppColors.primaryBlue,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    selectedOpt?.label ?? hint,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selectedOpt != null ? FontWeight.w600 : FontWeight.normal,
                      color: selectedOpt != null
                          ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tag & Chip Input Component (Add custom labels dynamically).
class TagInputWidget extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final String label;
  final String hint;

  const TagInputWidget({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.label = 'TAGS & LABELS',
    this.hint = 'Type tag and press enter...',
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _controller = TextEditingController();

  void _addTag(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isNotEmpty && !widget.tags.contains(cleaned)) {
      final updated = List<String>.from(widget.tags)..add(cleaned);
      widget.onTagsChanged(updated);
      _controller.clear();
    }
  }

  void _removeTag(String tag) {
    final updated = List<String>.from(widget.tags)..remove(tag);
    widget.onTagsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTypography.sectionLabel(isDark)),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ...widget.tags.map((tag) {
              return Chip(
                label: Text(tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                deleteIcon: const Icon(Icons.cancel_rounded, size: 14),
                onDeleted: () => _removeTag(tag),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                side: BorderSide.none,
              );
            }),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _controller,
                onSubmitted: _addTag,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
