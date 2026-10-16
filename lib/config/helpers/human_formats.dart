import 'package:intl/intl.dart';

class HumanFormats {
  const HumanFormats._();

  static String humanReadableNumber(double number) {
    return NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: '',
    ).format(number);
  }
}
