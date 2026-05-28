import 'dart:ui' as ui;
import 'package:intl/intl.dart';

class CurrencyHelper {
  /// Obtiene de manera dinámica el símbolo de la moneda según la configuración regional del dispositivo.
  static String get symbol {
    try {
      final String locale = Intl.defaultLocale ?? ui.PlatformDispatcher.instance.locale.toLanguageTag();
      final String currencyCode = _getCurrencyCodeForLocale(locale);
      return NumberFormat().simpleCurrencySymbol(currencyCode);
    } catch (_) {
      return 'Q'; // Fallback a Quetzales si ocurre un error
    }
  }

  /// Mapea locales/países comunes a su código de moneda ISO 4217 correspondiente.
  static String _getCurrencyCodeForLocale(String locale) {
    String countryCode = '';
    
    if (locale.contains('_')) {
      final List<String> parts = locale.split('_');
      if (parts.length > 1) {
        countryCode = parts.last;
      }
    } else if (locale.contains('-')) {
      final List<String> parts = locale.split('-');
      if (parts.length > 1) {
        countryCode = parts.last;
      }
    } else {
      countryCode = locale;
    }
    
    countryCode = countryCode.toUpperCase();
    
    final Map<String, String> countryToCurrency = <String, String>{
      'GT': 'GTQ', // Guatemala (Quetzal)
      'MX': 'MXN', // México (Peso)
      'US': 'USD', // Estados Unidos (Dólar)
      'ES': 'EUR', // España (Euro)
      'AR': 'ARS', // Argentina (Peso)
      'BO': 'BOB', // Bolivia (Boliviano)
      'BR': 'BRL', // Brasil (Real)
      'CL': 'CLP', // Chile (Peso)
      'CO': 'COP', // Colombia (Peso)
      'CR': 'CRC', // Costa Rica (Colón)
      'DO': 'DOP', // República Dominicana (Peso)
      'EC': 'USD', // Ecuador (Dólar)
      'SV': 'USD', // El Salvador (Dólar)
      'HN': 'HNL', // Honduras (Lempira)
      'NI': 'NIO', // Nicaragua (Córdoba)
      'PA': 'USD', // Panamá (Dólar)
      'PY': 'PYG', // Paraguay (Guaraní)
      'PE': 'PEN', // Perú (Sol)
      'PR': 'USD', // Puerto Rico (Dólar)
      'UY': 'UYU', // Uruguay (Peso)
      'VE': 'VES', // Venezuela (Bolívar)
      'CA': 'CAD', // Canadá (Dólar)
      'GB': 'GBP', // Reino Unido (Libra)
    };
    
    return countryToCurrency[countryCode] ?? 'GTQ';
  }

  /// Formatea el monto con el símbolo de la moneda correspondiente al locale del dispositivo.
  static String format(double amount) {
    try {
      final String currentSymbol = symbol;
      return NumberFormat.currency(
        locale: Intl.defaultLocale,
        symbol: currentSymbol,
        decimalDigits: 2,
      ).format(amount);
    } catch (_) {
      try {
        final String currentSymbol = symbol;
        return NumberFormat.currency(
          locale: 'es_GT',
          symbol: currentSymbol,
          decimalDigits: 2,
        ).format(amount);
      } catch (e) {
        return '$symbol${amount.toStringAsFixed(2)}';
      }
    }
  }
}
