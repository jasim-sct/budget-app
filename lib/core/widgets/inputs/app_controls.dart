import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../app_micro_pressable.dart';

/// Animated Custom Toggle Switch Component.
class AppToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  const AppToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (label != null)
          Text(
            label!,
            style: AppTypography.titleMedium(isDark),
          ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primaryBlue,
        ),
      ],
    );
  }
}

/// Segmented Control Component (Tabs / Period selector).
class AppSegmentedControl<T> extends StatelessWidget {
  final T selectedValue;
  final Map<T, String> options;
  final ValueChanged<T> onSelected;

  const AppSegmentedControl({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = entry.key == selectedValue;
          return Expanded(
            child: AppMicroPressable(
              onTap: () => onSelected(entry.key),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                curve: AppCurves.standard,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: AppRadius.borderSm,
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Numeric Stepper Component (+ / - amount or quantity adjuster).
class AppStepperInput extends StatelessWidget {
  final double value;
  final double step;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String label;

  const AppStepperInput({
    super.key,
    required this.value,
    this.step = 100.0,
    this.min = 0.0,
    this.max = 100000.0,
    required this.onChanged,
    this.label = 'AMOUNT STEPPER',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppTypography.sectionLabel(isDark)),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
            borderRadius: AppRadius.borderSm,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: value > min ? AppColors.primaryBlue : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
              ),
              Text(
                value.toStringAsFixed(2),
                style: AppTypography.currency(isDark, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: value < max ? AppColors.primaryBlue : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rating Widget (1 to 5 Stars / Priority level indicator).
class AppRatingInput extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final String label;

  const AppRatingInput({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.label = 'PRIORITY / IMPORTANCE',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppTypography.sectionLabel(isDark)),
          const SizedBox(height: AppSpacing.xs),
        ],
        Row(
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isFilled = starNumber <= rating;
            return IconButton(
              icon: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFilled ? AppColors.warningOrange : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                size: 26,
              ),
              onPressed: () => onRatingChanged(starNumber),
            );
          }),
        ),
      ],
    );
  }
}
