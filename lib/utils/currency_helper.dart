import 'package:intl/intl.dart';

class CurrencyHelper {
  static const String symbol = 'Q';

  /// Formatea el monto con el símbolo de Quetzal guatemalteco.
  static String format(double amount) =>
      NumberFormat.currency(symbol: 'Q', decimalDigits: 2).format(amount);
}
