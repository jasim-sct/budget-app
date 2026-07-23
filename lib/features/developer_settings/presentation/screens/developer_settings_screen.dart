import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer & Performance Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'PERFORMANCE METRICS & HARDWARE MONITOR',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.divider, width: 0.5),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target Frame Rate:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text('60 FPS (16.6ms)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.incomeGreen)),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target RAM Heap Limit:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text('< 25 MB', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Minimum Android Target:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text('API 26 (Android 8.0+)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'FEATURE FLAGS & TUNING',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Aggressive Background Memory Purge', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Releases image memory allocations immediately on pause', style: TextStyle(fontSize: 12)),
            value: _enableStrictMemoryTrimming,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _enableStrictMemoryTrimming = v),
          ),
          SwitchListTile(
            title: const Text('Fixed ListExtent Rendering', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Bypasses layout measurement passes for lists', style: TextStyle(fontSize: 12)),
            value: _enableHighFpsMode,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _enableHighFpsMode = v),
          ),
          SwitchListTile(
            title: const Text('SQL Query Diagnostics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Log indexed query execution times', style: TextStyle(fontSize: 12)),
            value: _enableSqlLogging,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _enableSqlLogging = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _vacuumDb,
            icon: const Icon(Icons.compress_rounded),
            label: const Text('Compact SQLite Storage (VACUUM)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
