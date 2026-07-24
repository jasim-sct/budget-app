import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../glass/glass_bottom_sheet.dart';

/// Reusable Date Picker helper dialog with customizable constraints.
class AppDatePicker {
  AppDatePicker._();

  static Future<DateTime?> selectDate(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primaryBlue,
                    onPrimary: Colors.white,
                    surface: AppColors.darkSurfaceElevated,
                    onSurface: AppColors.darkTextPrimary,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primaryBlue,
                    onPrimary: Colors.white,
                    surface: AppColors.lightSurfaceElevated,
                    onSurface: AppColors.lightTextPrimary,
                  ),
                ),
          child: child!,
        );
      },
    );
  }

  static Future<DateTimeRange?> selectDateRange(
    BuildContext context, {
    DateTimeRange? initialRange,
  }) async {
    final now = DateTime.now();
    return await showDateRangePicker(
      context: context,
      initialDateRange: initialRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
  }
}

/// Reusable Time Picker helper dialog.
class AppTimePicker {
  AppTimePicker._();

  static Future<TimeOfDay?> selectTime(
    BuildContext context, {
    TimeOfDay? initialTime,
  }) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
  }
}

/// Reusable Month & Year Selector Dialog.
class AppMonthPickerModal extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onSelected;

  const AppMonthPickerModal({
    super.key,
    required this.initialDate,
    required this.onSelected,
  });

  @override
  State<AppMonthPickerModal> createState() => _AppMonthPickerModalState();
}

class _AppMonthPickerModalState extends State<AppMonthPickerModal> {
  late int _selectedYear;
  late int _selectedMonth;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Month & Year', style: AppTypography.headline(isDark)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setState(() => _selectedYear--),
                  ),
                  Text(
                    '$_selectedYear',
                    style: AppTypography.headline(isDark).copyWith(fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => setState(() => _selectedYear++),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: AppSpacing.xs,
              mainAxisSpacing: AppSpacing.xs,
              childAspectRatio: 1.8,
            ),
            itemBuilder: (context, index) {
              final monthNum = index + 1;
              final isSelected = monthNum == _selectedMonth;

              return InkWell(
                onTap: () {
                  setState(() => _selectedMonth = monthNum);
                  widget.onSelected(DateTime(_selectedYear, _selectedMonth, 1));
                  Navigator.pop(context);
                },
                borderRadius: AppRadius.borderSm,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Text(
                    _months[index],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Color Picker Widget for Custom Wallet & Category styling.
class AppColorPickerWidget extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  static const List<int> defaultPalette = [
    0xFF2563EB, 0xFF10B981, 0xFF8B5CF6, 0xFFEC4899,
    0xFFF59E0B, 0xFFEF4444, 0xFF06B6D4, 0xFF6366F1,
    0xFF14B8A6, 0xFFF97316, 0xFF84CC16, 0xFF64748B,
  ];

  const AppColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: defaultPalette.map((colorVal) {
          final isSelected = selectedColor == colorVal;
          return GestureDetector(
            onTap: () => onColorSelected(colorVal),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Color(colorVal),
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: isDark ? Colors.white : AppColors.lightTextPrimary, width: 2.5)
                    : null,
                boxShadow: isSelected
                    ? [BoxShadow(color: Color(colorVal).withValues(alpha: 0.4), blurRadius: 6)]
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Financial Emoji Selection Grid Widget.
class AppEmojiPickerWidget extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;

  static const List<String> financialEmojis = [
    '💵', '💰', '💳', '🏦', '📈', '📉', '🛒', '🚗', '⛽', '🏠',
    '🍔', '☕', '🎁', '✈️', '🎓', '🏥', '🍿', '💡', '📱', '🔧',
    '💼', '🪙', '💎', '🎉', '🌴', '🐾', '🚴', '🍔', '🎨', '🔒'
  ];

  const AppEmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: financialEmojis.map((emoji) {
        return InkWell(
          onTap: () => onEmojiSelected(emoji),
          borderRadius: AppRadius.borderSm,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.2)),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        );
      }).toList(),
    );
  }
}
