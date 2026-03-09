import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class CurrencyHelper {
  /// Devuelve el símbolo de la moneda basado en la ubicación local del dispositivo.
  static String get symbol {
    final String localeName = kIsWeb ? 'en_US' : Platform.localeName;
    return NumberFormat.simpleCurrency(locale: localeName).currencySymbol;
  }

  /// Formatea el monto dado usando la moneda local del dispositivo.
  static String format(double amount) {
    final String localeName = kIsWeb ? 'en_US' : Platform.localeName;
    return NumberFormat.simpleCurrency(locale: localeName).format(amount);
  }
}
