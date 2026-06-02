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
      'step1Title': 'Take Control',
      'step1Desc':
          'Track every cent. Record income and expenses automatically and see where your money goes.',
      'step1Badge': 'Total Control',
      'step1Pill1': 'Auto Sync',
      'step1Pill2': 'Real-time Insights',
      'step2Title': 'Say Goodbye to Debt',
      'step2Desc':
          'Break the debt cycle. Learn to manage your credit and keep your finances free of burdens.',
      'step2Badge': 'Debt Free',
      'step3Title': 'Your Path to Freedom',
      'step3Desc':
          'Build your future. Save, invest and reach the financial freedom you deserve with clear goals.',
      'step3Badge': 'Financial Freedom',
      'step3Achievement': 'Goal Reached',
      'getStartedNow': 'Start Now',
      'alreadyHaveAccount': 'Already have an account? Sign in',
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
      'step1Title': 'Toma el Control',
      'step1Desc':
          'Controla cada centavo. Registra tus gastos e ingresos de forma automática y visualiza a dónde va tu dinero.',
      'step1Badge': 'Control Total',
      'step1Pill1': 'Sincronización Automática',
      'step1Pill2': 'Insights en Tiempo Real',
      'step2Title': 'Dile Adiós a las Deudas',
      'step2Desc':
          'Evita el ciclo de la deuda. Aprende a gestionar tus créditos y mantén tu salud financiera libre de compromisos.',
      'step2Badge': 'Vida sin Deudas',
      'step3Title': 'Tu Camino a la Libertad',
      'step3Desc':
          'Construye tu futuro. Ahorra, invierte y alcanza la libertad financiera que mereces con metas claras.',
      'step3Badge': 'Libertad Financiera',
      'step3Achievement': 'Meta alcanzada',
      'getStartedNow': 'Comenzar Ahora',
      'alreadyHaveAccount': '¿Ya tienes una cuenta? Iniciar sesión',
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
  String get step1Pill1 => _text('step1Pill1');
  String get step1Pill2 => _text('step1Pill2');
  String get step3Achievement => _text('step3Achievement');
  String get getStartedNow => _text('getStartedNow');
  String get alreadyHaveAccount => _text('alreadyHaveAccount');
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
