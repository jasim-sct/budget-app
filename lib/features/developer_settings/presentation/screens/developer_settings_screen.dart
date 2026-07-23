import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

class DeveloperSettingsScreen extends StatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  State<DeveloperSettingsScreen> createState() => _DeveloperSettingsScreenState();
}

class _DeveloperSettingsScreenState extends State<DeveloperSettingsScreen> {
  bool _enableHighFpsMode = true;
  bool _enableStrictMemoryTrimming = true;
  bool _enableSqlLogging = false;

  Future<void> _vacuumDb() async {
    final db = await AppDatabase.instance.database;
    await db.execute('VACUUM;');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('eMMC Database Compacted & Vacuumed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer & Hardware Diagnostics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'PERFORMANCE METRICS & HARDWARE MONITOR',
            style: AppTypography.labelSmall(isDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _buildMetricRow('Target Frame Rate', '60 FPS (16.6ms)', AppColors.incomeGreen, isDark),
                const SizedBox(height: 6),
                _buildMetricRow('Target RAM Heap Limit', '< 25 MB', AppColors.primaryEmerald, isDark),
                const SizedBox(height: 6),
                _buildMetricRow('Minimum Target OS', 'Android 8.0+ / Linux', isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'FEATURE FLAGS & TUNING',
            style: AppTypography.labelSmall(isDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            title: Text('Aggressive Background Memory Purge', style: AppTypography.titleMedium(isDark)),
            subtitle: Text('Releases image memory allocations immediately on pause', style: AppTypography.bodyMedium(isDark)),
            value: _enableStrictMemoryTrimming,
            activeTrackColor: AppColors.primaryEmerald,
            onChanged: (v) => setState(() => _enableStrictMemoryTrimming = v),
          ),
          SwitchListTile(
            title: Text('Fixed ListExtent Rendering', style: AppTypography.titleMedium(isDark)),
            subtitle: Text('Bypasses layout measurement passes for lists', style: AppTypography.bodyMedium(isDark)),
            value: _enableHighFpsMode,
            activeTrackColor: AppColors.primaryEmerald,
            onChanged: (v) => setState(() => _enableHighFpsMode = v),
          ),
          SwitchListTile(
            title: Text('SQL Query Diagnostics', style: AppTypography.titleMedium(isDark)),
            subtitle: Text('Log indexed query execution times', style: AppTypography.bodyMedium(isDark)),
            value: _enableSqlLogging,
            activeTrackColor: AppColors.primaryEmerald,
            onChanged: (v) => setState(() => _enableSqlLogging = v),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: _vacuumDb,
            icon: const Icon(Icons.compress_rounded),
            label: const Text('Compact SQLite Storage (VACUUM)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium(isDark)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
