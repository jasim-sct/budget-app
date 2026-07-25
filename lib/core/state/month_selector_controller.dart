import 'package:flutter/material.dart';
import '../services/user_settings_store.dart';

/// Global Month Selector Controller.
/// Controls active month/year selection application-wide.
/// Enforces that no month prior to the app install month can be selected.
class MonthSelectorController extends ValueNotifier<DateTime> {
  static MonthSelectorController? _instance;
  DateTime? _installMonthStart;

  MonthSelectorController._internal()
      : super(DateTime(DateTime.now().year, DateTime.now().month)) {
    _loadInstallBound();
  }

  static MonthSelectorController get instance {
    _instance ??= MonthSelectorController._internal();
    return _instance!;
  }

  Future<void> _loadInstallBound() async {
    _installMonthStart = await UserSettingsStore.instance.getAppInstallMonthStart();
    if (value.isBefore(_installMonthStart!)) {
      value = _installMonthStart!;
    }
  }

  DateTime get installMonthStart =>
      _installMonthStart ?? DateTime(DateTime.now().year, DateTime.now().month, 1);

  int get selectedYear => value.year;
  int get selectedMonth => value.month;

  void selectMonth(DateTime newMonth) {
    var target = DateTime(newMonth.year, newMonth.month, 1);
    if (_installMonthStart != null && target.isBefore(_installMonthStart!)) {
      target = _installMonthStart!;
    }
    if (value.year != target.year || value.month != target.month) {
      value = target;
    }
  }

  void previousMonth() {
    final prev = DateTime(value.year, value.month - 1, 1);
    if (_installMonthStart != null && prev.isBefore(_installMonthStart!)) {
      value = _installMonthStart!;
      return;
    }
    value = prev;
  }

  void nextMonth() {
    value = DateTime(value.year, value.month + 1, 1);
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    selectMonth(DateTime(now.year, now.month, 1));
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return value.year == now.year && value.month == now.month;
  }

  bool get isAtInstallMonth {
    if (_installMonthStart == null) return false;
    return value.year == _installMonthStart!.year && value.month == _installMonthStart!.month;
  }
}
