import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:personal_finance/utils/currency_helper.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>>
  _localizedValues = <String, Map<String, String>>{
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
      'step1Title': 'Know where your money goes',
      'step1Desc':
          'Log income and expenses in seconds. Real-time balance, always in your pocket.',
      'step1Badge': 'Full Control',
      'step2Title': 'Your progress, always visible',
      'step2Desc':
          'Analyze by day, week, or month. Spot patterns and make smarter financial decisions.',
      'step2Badge': 'Smart Analytics',
      'step3Title': "Goals you'll actually reach",
      'step3Desc':
          'Set targets for 3, 6 months or 1 year. We show you exactly how much to save each week.',
      'step3Badge': 'Strategic Saving',
      'skip': 'Skip',
      'step4Title': 'How will you use the app?',
      'step4Desc': 'Choose the profile that best fits you.',
      'usagePersonal': 'Personal Finance',
      'usageBusiness': 'My Business',
      'usageBoth': 'Both',
      // Paywall
      'paywallSubtitle': 'Take full control of your finances',
      'paywallPerMonth': 'per month · cancel anytime',
      'paywallGetPro': 'Get Pro Now',
      'paywallRestore': 'Restore purchases',
      'paywallTerms': 'Terms of Use',
      'paywallPrivacy': 'Privacy Policy',
      // AI Chat
      'aiChatTitle': 'Financial Assistant',
      'aiChatBadge': 'Powered by AI · Pro',
      'aiChatWelcome':
          "Hi! I'm your personal financial assistant. I can help you understand your expenses, analyze your finances and give you personalized recommendations.\n\nHow can I help you today?",
      'aiChatComingSoon': 'AI chat will be available very soon. Stay tuned!',
      'aiChatHint': 'Type your financial question…',
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
      'step1Title': 'Sabe a dónde va tu dinero',
      'step1Desc':
          'Registra ingresos y gastos en segundos. Tu balance real, siempre en tu bolsillo.',
      'step1Badge': 'Control total',
      'step2Title': 'Tu progreso, siempre visible',
      'step2Desc':
          'Analiza por día, semana o mes. Detecta patrones y toma mejores decisiones financieras.',
      'step2Badge': 'Análisis inteligente',
      'step3Title': 'Metas que sí se cumplen',
      'step3Desc':
          'Define objetivos a 3, 6 meses o 1 año. Te mostramos cuánto ahorrar cada semana para lograrlo.',
      'step3Badge': 'Ahorro estratégico',
      'skip': 'Saltar',
      'step4Title': '¿Para qué usarás la app?',
      'step4Desc': 'Elige el perfil que mejor se adapte a ti.',
      'usagePersonal': 'Finanzas Personales',
      'usageBusiness': 'Mi Negocio',
      'usageBoth': 'Ambas',
      // Paywall
      'paywallSubtitle': 'Toma el control total de tus finanzas',
      'paywallPerMonth': 'por mes · cancela cuando quieras',
      'paywallGetPro': 'Obtener Pro Ahora',
      'paywallRestore': 'Restaurar compras',
      'paywallTerms': 'Términos de Uso',
      'paywallPrivacy': 'Política de Privacidad',
      // AI Chat
      'aiChatTitle': 'Asistente Financiero',
      'aiChatBadge': 'Impulsado por IA · Pro',
      'aiChatWelcome':
          '¡Hola! Soy tu asistente financiero personal. Puedo ayudarte a entender tus gastos, analizar tus finanzas y darte recomendaciones personalizadas.\n\n¿En qué te puedo ayudar hoy?',
      'aiChatComingSoon':
          'El chat con IA estará disponible muy pronto. ¡Mantente al tanto!',
      'aiChatHint': 'Escribe tu pregunta financiera…',
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
  String get step4Title => _text('step4Title');
  String get step4Desc => _text('step4Desc');
  String get usagePersonal => _text('usagePersonal');
  String get usageBusiness => _text('usageBusiness');
  String get usageBoth => _text('usageBoth');

  // Paywall
  String get paywallSubtitle => _text('paywallSubtitle');
  String get paywallPerMonth => _text('paywallPerMonth');
  String get paywallGetPro => _text('paywallGetPro');
  String get paywallRestore => _text('paywallRestore');
  String get paywallTerms => _text('paywallTerms');
  String get paywallPrivacy => _text('paywallPrivacy');

  // AI Chat
  String get aiChatTitle => _text('aiChatTitle');
  String get aiChatBadge => _text('aiChatBadge');
  String get aiChatWelcome => _text('aiChatWelcome');
  String get aiChatComingSoon => _text('aiChatComingSoon');
  String get aiChatHint => _text('aiChatHint');

  NumberFormat get currencyFormatter {
    final String localeName =
        kIsWeb ? locale.toLanguageTag() : Platform.localeName;
    try {
      return NumberFormat.currency(
        locale: localeName,
        symbol: CurrencyHelper.symbol,
        decimalDigits: 2,
      );
    } catch (_) {
      return NumberFormat.simpleCurrency(locale: localeName);
    }
  }

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
