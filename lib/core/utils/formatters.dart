/// Fast, lightweight formatting utilities without third-party `intl` package heap overhead.
abstract class AppFormatters {
  static String currency(double amount, {String symbol = '\$'}) {
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
    final String result = '$symbol$reversedInt.$decPart';

    return isNegative ? '-$result' : result;
  }

  static String date(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String dateShort(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = months[dt.month - 1];
    return '$monthName ${dt.day}, ${dt.year}';
  }
}
