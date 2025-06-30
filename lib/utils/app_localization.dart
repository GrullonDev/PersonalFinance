import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get currencySymbol {
    switch (locale.countryCode) {
      case 'GT':
        return 'Q'; // Quetzal guatemalteco
      case 'US':
        return '\$'; // Dólar estadounidense
      case 'MX':
        return '\$'; // Peso mexicano
      case 'ES':
        return '€'; // Euro
      default:
        return '\$'; // Símbolo por defecto
    }
  }

  NumberFormat get currencyFormatter {
    return NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return <String>['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
