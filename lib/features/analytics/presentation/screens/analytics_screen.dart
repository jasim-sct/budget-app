import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/gpu_pie_chart_painter.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample spending breakdown data for demonstration
    final List<double> values = [450.0, 220.0, 180.0, 120.0, 90.0];
    final List<String> labels = ['Food', 'Transport', 'Utilities', 'Shopping', 'Others'];
    final List<Color> colors = const [
      AppTheme.expenseRed,
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Visuals'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'EXPENSE BREAKDOWN BY CATEGORY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          // Donut Chart Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.divider, width: 0.5),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: GpuPieChartPainter(
                      values: values,
                      colors: colors,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Legend
                ...List.generate(labels.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[index],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              labels[index],
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        Text(
                          '\$${values[index].toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
