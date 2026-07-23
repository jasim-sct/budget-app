import 'package:flutter_test/flutter_test.dart';
import 'package:budget_lite/core/utils/formatters.dart';

void main() {
  group('AppFormatters Tests', () {
    test('Currency formatting handles positive and negative amounts correctly', () {
      expect(AppFormatters.currency(1234.56), '\$1,234.56');
      expect(AppFormatters.currency(-50.00), '-\$50.00');
      expect(AppFormatters.currency(0.0), '\$0.00');
    });

    test('Date formatting outputs ISO yyyy-MM-dd format', () {
      final dt = DateTime(2026, 7, 23);
      expect(AppFormatters.date(dt), '2026-07-23');
    });
  });
}
