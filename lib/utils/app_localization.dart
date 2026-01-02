import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues =
      <String, Map<String, String>>{
        'en': <String, String>{
          'welcome': 'Welcome to your personal finance app!',
          'start': 'Start',
          'appTitle': 'Personal Finance',
          'back': 'Back',
          'next': 'Next',
          'getStarted': 'Get Started',
          'signInToContinue': 'Sign in to continue',
          'continueWithGoogle': 'Continue with Google',
          'continueWithApple': 'Continue with Apple',
          'totalBalance': 'TOTAL BALANCE',
          'positiveBalance': 'Positive Balance',
          'negativeBalance': 'Negative Balance',
          'add': 'Add',
          'addIncome': 'Add Income',
          'addExpense': 'Add Expense',
          'step1Title': 'Track your expenses',
          'step1Desc': 'Add transactions quickly and easily.',
          'step2Title': 'See your progress',
          'step2Desc': 'Check your daily, weekly or monthly balance.',
          'step3Title': 'Learn tips',
          'step3Desc': 'Get personalized financial advice every day.',
        },
        'es': <String, String>{
          'welcome': '¡Bienvenido a tu app de finanzas personales!',
          'start': 'Iniciar',
          'appTitle': 'Finanzas Personales',
          'back': 'Atrás',
          'next': 'Siguiente',
          'getStarted': 'Comenzar',
          'signInToContinue': 'Inicia sesión para continuar',
          'continueWithGoogle': 'Continuar con Google',
          'continueWithApple': 'Continuar con Apple',
          'totalBalance': 'BALANCE TOTAL',
          'positiveBalance': 'Saldo Positivo',
          'negativeBalance': 'Saldo Negativo',
          'add': 'Agregar',
          'addIncome': 'Agregar Ingreso',
          'addExpense': 'Agregar Gasto',
          'step1Title': 'Registra tus gastos',
          'step1Desc': 'Añade transacciones de forma rápida y sencilla.',
          'step2Title': 'Visualiza tu progreso',
          'step2Desc': 'Consulta tu balance diario, semanal o mensual.',
          'step3Title': 'Aprende consejos',
          'step3Desc': 'Recibe tips financieros personalizados cada día.',
        },
      };

  String _text(String key) =>
      _localizedValues[locale.languageCode]?[key] ??
      _localizedValues['es']![key]!;

  /// Returns the localized string for the given [key].
  String translate(String key) => _text(key);

  String get welcome => _text('welcome');
  String get start => _text('start');
  String get appTitle => _text('appTitle');
  String get back => _text('back');
  String get next => _text('next');
  String get getStarted => _text('getStarted');
  String get signInToContinue => _text('signInToContinue');
  String get continueWithGoogle => _text('continueWithGoogle');
  String get continueWithApple => _text('continueWithApple');
  String get totalBalance => _text('totalBalance');
  String get positiveBalance => _text('positiveBalance');
  String get negativeBalance => _text('negativeBalance');
  String get add => _text('add');
  String get addIncome => _text('addIncome');
  String get addExpense => _text('addExpense');
  String get step1Title => _text('step1Title');
  String get step1Desc => _text('step1Desc');
  String get step2Title => _text('step2Title');
  String get step2Desc => _text('step2Desc');
  String get step3Title => _text('step3Title');
  String get step3Desc => _text('step3Desc');

  NumberFormat get currencyFormatter =>
      NumberFormat.simpleCurrency(locale: locale.toLanguageTag());

  NumberFormat get decimalFormatter =>
      NumberFormat.decimalPattern(locale.toLanguageTag());

  String formatDate(DateTime date) =>
      DateFormat.yMd(locale.toLanguageTag()).format(date);

  /// Obtiene el símbolo de moneda según el locale
  String get currencySymbol => currencyFormatter.currencySymbol;

  /// Formatea un monto como moneda según el locale del dispositivo
  String formatCurrency(double amount) => currencyFormatter.format(amount);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
