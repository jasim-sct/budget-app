import '../database/database_helper.dart';
import '../utils/formatters.dart';

class InsightItem {
  final String title;
  final String description;
  final String value;
  final String type; // 'warning', 'positive', 'neutral'

  const InsightItem({
    required this.title,
    required this.description,
    required this.value,
    required this.type,
  });
}

/// Dynamic Automated Financial Insights Engine.
/// Derives actionable insights directly from single source of truth SQLite ledger.
class InsightsEngine {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  static Future<List<InsightItem>> generateInsightsForMonth(int year, int month) async {
    final totals = await _db.getSummaryTotalsByMonth(year, month);
    final income = totals['income'] ?? 0.0;
    final expense = totals['expense'] ?? 0.0;
    final savingsRate = income > 0 ? ((income - expense) / income * 100).clamp(0.0, 100.0) : 0.0;

    final breakdown = await _db.getCategoryBreakdownByMonth(year, month);

    final List<InsightItem> insights = [];

    // 1. Savings Rate Insight
    if (savingsRate >= 20.0) {
      insights.add(
        InsightItem(
          title: 'Strong Savings Rate',
          description: 'You saved ${savingsRate.toStringAsFixed(1)}% of your income this month. Excellent discipline!',
          value: '${savingsRate.toStringAsFixed(0)}%',
          type: 'positive',
        ),
      );
    } else if (expense > income && income > 0) {
      final deficit = expense - income;
      insights.add(
        InsightItem(
          title: 'Cash Flow Deficit Alert',
          description: 'Expenses exceed income by ${AppFormatters.currency(deficit)} this month.',
          value: '-${AppFormatters.currency(deficit)}',
          type: 'warning',
        ),
      );
    }

    // 2. Highest Spending Category
    if (breakdown.isNotEmpty) {
      final topCat = breakdown.first;
      final catName = topCat['category'] as String;
      final catTotal = (topCat['total'] as num).toDouble();
      final catPct = expense > 0 ? ((catTotal / expense) * 100).toStringAsFixed(0) : '0';

      insights.add(
        InsightItem(
          title: 'Top Category Outflow',
          description: '$catName represents $catPct% of all expenses in ${AppFormatters.monthName(month)}.',
          value: AppFormatters.currency(catTotal),
          type: 'neutral',
        ),
      );
    }

    // 3. Daily Average Spending
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dailyAvg = expense / daysInMonth;
    insights.add(
      InsightItem(
        title: 'Daily Spend Burn Rate',
        description: 'Averaging ${AppFormatters.currency(dailyAvg)} per day across $daysInMonth days.',
        value: '${AppFormatters.currency(dailyAvg)}/day',
        type: 'neutral',
      ),
    );

    return insights;
  }
}
