import 'package:personal_finance/features/subscription/domain/entities/subscription_entity.dart';

class PlanPricing {
  static const double proMonthly = 5.99;

  static String get proMonthlyFormatted => '\$${proMonthly.toStringAsFixed(2)}';
}

class PlanLimits {
  final int maxBudgets;
  final int maxGoals;
  final int maxAccounts;

  static const int unlimited = -1;

  const PlanLimits({
    required this.maxBudgets,
    required this.maxGoals,
    required this.maxAccounts,
  });

  bool isUnlimited(int value) => value == unlimited;

  static const PlanLimits free = PlanLimits(
    maxBudgets: 1,
    maxGoals: 1,
    maxAccounts: 1,
  );

  static const PlanLimits pro = PlanLimits(
    maxBudgets: unlimited,
    maxGoals: unlimited,
    maxAccounts: unlimited,
  );

  static PlanLimits forTier(PlanTier tier) =>
      tier.isPro ? PlanLimits.pro : PlanLimits.free;
}

class PlanFeatures {
  static const Set<PlanFeature> freeFeatures = {};

  static const Set<PlanFeature> proFeatures = {
    PlanFeature.unlimitedBudgets,
    PlanFeature.unlimitedGoals,
    PlanFeature.unlimitedAccounts,
    PlanFeature.aiChat,
    PlanFeature.monthlyAiReports,
    PlanFeature.predictiveAlerts,
    PlanFeature.exportCsvPdf,
    PlanFeature.recurringTransactions,
    PlanFeature.premiumThemes,
    PlanFeature.homeWidget,
  };

  static Set<PlanFeature> forTier(PlanTier tier) =>
      tier.isPro ? proFeatures : freeFeatures;
}

class PlanFeatureLabels {
  static const Map<PlanFeature, ({String title, String description})> _en = {
    PlanFeature.unlimitedBudgets: (
      title: 'Unlimited budgets',
      description: 'Create as many budgets as you need',
    ),
    PlanFeature.unlimitedGoals: (
      title: 'Unlimited savings goals',
      description: 'Set and track unlimited financial goals',
    ),
    PlanFeature.unlimitedAccounts: (
      title: 'Multi-account management',
      description: 'Bank accounts, cash, and credit cards',
    ),
    PlanFeature.aiChat: (
      title: 'AI financial assistant',
      description: 'Ask questions in natural language',
    ),
    PlanFeature.monthlyAiReports: (
      title: 'Monthly AI reports',
      description: 'PDF reports with analytics and recommendations',
    ),
    PlanFeature.predictiveAlerts: (
      title: 'Predictive budget alerts',
      description: 'Know before you overspend — days in advance',
    ),
    PlanFeature.exportCsvPdf: (
      title: 'Export CSV & PDF',
      description: 'Download your financial data anytime',
    ),
    PlanFeature.recurringTransactions: (
      title: 'Recurring transactions',
      description: 'Automate salaries, rent, and subscriptions',
    ),
    PlanFeature.premiumThemes: (
      title: 'Premium themes',
      description: 'AMOLED dark mode and custom color palettes',
    ),
    PlanFeature.homeWidget: (
      title: 'Home screen widget',
      description: 'Balance and budget progress at a glance',
    ),
  };

  static const Map<PlanFeature, ({String title, String description})> _es = {
    PlanFeature.unlimitedBudgets: (
      title: 'Presupuestos ilimitados',
      description: 'Crea todos los presupuestos que necesites',
    ),
    PlanFeature.unlimitedGoals: (
      title: 'Metas de ahorro ilimitadas',
      description: 'Establece y rastrea metas financieras sin límite',
    ),
    PlanFeature.unlimitedAccounts: (
      title: 'Gestión multi-cuenta',
      description: 'Cuentas bancarias, efectivo y tarjetas de crédito',
    ),
    PlanFeature.aiChat: (
      title: 'Asistente financiero con IA',
      description: 'Haz preguntas en lenguaje natural',
    ),
    PlanFeature.monthlyAiReports: (
      title: 'Reportes mensuales con IA',
      description: 'Informes PDF con análisis y recomendaciones',
    ),
    PlanFeature.predictiveAlerts: (
      title: 'Alertas predictivas de presupuesto',
      description: 'Sabe antes de gastar de más — con días de anticipación',
    ),
    PlanFeature.exportCsvPdf: (
      title: 'Exportar CSV y PDF',
      description: 'Descarga tus datos financieros en cualquier momento',
    ),
    PlanFeature.recurringTransactions: (
      title: 'Transacciones recurrentes',
      description: 'Automatiza salarios, alquiler y suscripciones',
    ),
    PlanFeature.premiumThemes: (
      title: 'Temas premium',
      description: 'Modo oscuro AMOLED y paletas de colores personalizadas',
    ),
    PlanFeature.homeWidget: (
      title: 'Widget en pantalla de inicio',
      description: 'Balance y progreso de presupuesto de un vistazo',
    ),
  };

  // Kept for backwards compatibility — defaults to English.
  static const Map<PlanFeature, ({String title, String description})> labels =
      _en;

  static Map<PlanFeature, ({String title, String description})> labelsFor(
    String languageCode,
  ) => languageCode == 'es' ? _es : _en;
}
