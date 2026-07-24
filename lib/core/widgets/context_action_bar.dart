import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A contextual action item displayed in the ContextActionBar.
class ContextActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const ContextActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });
}

/// Intent-driven contextual action bar that replaces FAB + modal.
/// Shows 2-3 relevant actions based on the current screen context.
/// Sits above the bottom navigation bar, always visible.
class ContextActionBar extends StatelessWidget {
  final List<ContextActionItem> actions;

  const ContextActionBar({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: actions.map((action) {
          final isFirst = action == actions.first;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: isFirst ? 0 : AppSpacing.xs),
              child: _ActionChip(action: action, isDark: isDark),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionChip extends StatefulWidget {
  final ContextActionItem action;
  final bool isDark;

  const _ActionChip({required this.action, required this.isDark});

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.action.isPrimary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.action.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.primaryBlue
                : (widget.isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceSecondary),
            borderRadius: AppRadius.borderSm,
            border: isPrimary
                ? null
                : Border.all(
                    color: widget.isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 1,
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.action.icon,
                size: 16,
                color: isPrimary
                    ? Colors.white
                    : (widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPrimary
                        ? Colors.white
                        : (widget.isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
