import '../services/currency_provider.dart';

/// Fast, lightweight formatting utilities without third-party `intl` package heap overhead.
abstract class AppFormatters {
  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> shortMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String currency(double amount, {String? symbol}) {
    final String actualSymbol = symbol ?? CurrencyProvider.instance.currentSymbol;
    final bool isNegative = amount < 0;
    final double absAmount = amount.abs();
    final String formatted = absAmount.toStringAsFixed(2);
    
    // Split integer and decimal parts
    final parts = formatted.split('.');
    final String intPart = parts[0];
    final String decPart = parts[1];

    // Add thousands commas manually
    final buffer = StringBuffer();
    int count = 0;

    for (int i = intPart.length - 1; i >= 0; i--) {
      buffer.write(intPart[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }

    final String reversedInt = buffer.toString().split('').reversed.join('');
    final String result = '$actualSymbol$reversedInt.$decPart';

    return isNegative ? '-$result' : result;
  }

  static String date(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String dateShort(DateTime dt) {
    final monthName = shortMonthNames[dt.month - 1];
    return '$monthName ${dt.day}, ${dt.year}';
  }

  static String dateShortFromMs(int ms) {
    return dateShort(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  static String monthName(int month) {
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return '';
  }

  static String monthYear(DateTime dt) {
    return '${monthNames[dt.month - 1]} ${dt.year}';
  }

  static String shortMonthYear(DateTime dt) {
    return '${shortMonthNames[dt.month - 1]} ${dt.year}';
  }
}
