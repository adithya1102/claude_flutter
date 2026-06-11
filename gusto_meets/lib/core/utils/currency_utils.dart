import 'package:intl/intl.dart';

class CurrencyUtils {
  CurrencyUtils._();

  static final _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 0,
  );

  static String formatINR(double amount) => _formatter.format(amount);

  static String formatINRWithDecimal(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    ).format(amount);
  }

  static String formatINRDecimal(double amount) => formatINRWithDecimal(amount);
}
