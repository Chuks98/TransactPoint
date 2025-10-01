import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {bool withSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: withSymbol ? '₦' : '',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
