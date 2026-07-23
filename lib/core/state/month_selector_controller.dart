import 'package:flutter/material.dart';

/// Global Month Selector Controller.
/// Controls active month/year selection application-wide.
/// Changing the selected month notifies all listening screens and repositories instantly.
class MonthSelectorController extends ValueNotifier<DateTime> {
  static MonthSelectorController? _instance;

  MonthSelectorController._internal()
      : super(DateTime(DateTime.now().year, DateTime.now().month));

  static MonthSelectorController get instance {
    _instance ??= MonthSelectorController._internal();
    return _instance!;
  }

  int get selectedYear => value.year;
  int get selectedMonth => value.month;

  void selectMonth(DateTime newMonth) {
    final target = DateTime(newMonth.year, newMonth.month);
    if (value.year != target.year || value.month != target.month) {
      value = target;
    }
  }

  void previousMonth() {
    value = DateTime(value.year, value.month - 1);
  }

  void nextMonth() {
    value = DateTime(value.year, value.month + 1);
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    value = DateTime(now.year, now.month);
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return value.year == now.year && value.month == now.month;
  }
}
