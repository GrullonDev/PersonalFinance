import 'package:personal_finance/features/subscription/domain/entities/subscription_entity.dart';

class PlanPricing {
  /// Precio de referencia. El cobro real lo define la tienda (App Store
  /// Connect / Play Console) y el paywall muestra el precio que ella reporta.
  static const double proMonthly = 2.99;

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
    maxBudgets: 2,
    maxGoals: 2,
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

  /// Lo que hoy entrega Pro. Las funciones aún no implementadas
  /// (multi-cuenta, recurrentes, widget) no se ofrecen hasta que existan.
  static const Set<PlanFeature> proFeatures = {
    PlanFeature.aiChat,
    PlanFeature.monthlyAiReports,
    PlanFeature.predictiveAlerts,
    PlanFeature.unlimitedBudgets,
    PlanFeature.unlimitedGoals,
    PlanFeature.exportCsvPdf,
    PlanFeature.premiumThemes,
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
      title: 'Unlimited AI assistant',
      description: 'Ask about your own spending, debts and budgets',
    ),
    PlanFeature.monthlyAiReports: (
      title: 'Monthly AI report',
      description: 'Where your money went and how to save more',
    ),
    PlanFeature.predictiveAlerts: (
      title: 'Early budget alerts',
      description: 'Get warned at 80% before you overspend',
    ),
    PlanFeature.exportCsvPdf: (
      title: 'Export your data',
      description: 'Download your transactions as CSV anytime',
    ),
    PlanFeature.recurringTransactions: (
      title: 'Recurring transactions',
      description: 'Automate salaries, rent, and subscriptions',
    ),
    PlanFeature.premiumThemes: (
      title: 'Premium themes',
      description: 'AMOLED dark mode and exclusive color palettes',
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
      title: 'Asistente con IA ilimitado',
      description: 'Pregunta sobre tus gastos, deudas y presupuestos reales',
    ),
    PlanFeature.monthlyAiReports: (
      title: 'Reporte mensual con IA',
      description: 'En qué se fue tu dinero y cómo ahorrar más',
    ),
    PlanFeature.predictiveAlerts: (
      title: 'Alertas anticipadas de presupuesto',
      description: 'Aviso al llegar al 80 %, antes de pasarte',
    ),
    PlanFeature.exportCsvPdf: (
      title: 'Exporta tus datos',
      description: 'Descarga tus movimientos en CSV cuando quieras',
    ),
    PlanFeature.recurringTransactions: (
      title: 'Transacciones recurrentes',
      description: 'Automatiza salarios, alquiler y suscripciones',
    ),
    PlanFeature.premiumThemes: (
      title: 'Temas premium',
      description: 'Modo oscuro AMOLED y paletas de colores exclusivas',
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

/// Fila de la comparación Gratis vs Pro del paywall.
class PlanComparisonRow {
  const PlanComparisonRow(this.label, this.free, this.pro);

  final String label;

  /// Texto de la columna; `null` = no incluido, `''` = incluido (✓).
  final String? free;
  final String? pro;
}

class PlanComparison {
  static List<PlanComparisonRow> rows(String languageCode) {
    final free = PlanLimits.free;
    return languageCode == 'es'
        ? [
          const PlanComparisonRow(
            'Registro rápido y categorías automáticas',
            '',
            '',
          ),
          const PlanComparisonRow(
            'Captura automática de pagos (notificaciones, SMS, Apple Pay)',
            '',
            '',
          ),
          const PlanComparisonRow('Abono automático a tus deudas', '', ''),
          PlanComparisonRow('Presupuestos', '${free.maxBudgets}', 'Ilimitados'),
          PlanComparisonRow(
            'Metas de ahorro',
            '${free.maxGoals}',
            'Ilimitadas',
          ),
          const PlanComparisonRow(
            'Alertas de presupuesto',
            'Al 100 %',
            'Al 80 % y 100 %',
          ),
          const PlanComparisonRow('Asistente con IA', '3 al día', 'Ilimitado'),
          const PlanComparisonRow('Reporte mensual con IA', null, ''),
          const PlanComparisonRow('Exportar datos (CSV)', null, ''),
          const PlanComparisonRow('Temas premium', null, ''),
        ]
        : [
          const PlanComparisonRow(
            'Quick entry and automatic categories',
            '',
            '',
          ),
          const PlanComparisonRow(
            'Automatic payment capture (notifications, SMS, Apple Pay)',
            '',
            '',
          ),
          const PlanComparisonRow('Automatic debt payments', '', ''),
          PlanComparisonRow('Budgets', '${free.maxBudgets}', 'Unlimited'),
          PlanComparisonRow('Savings goals', '${free.maxGoals}', 'Unlimited'),
          const PlanComparisonRow('Budget alerts', 'At 100%', 'At 80% & 100%'),
          const PlanComparisonRow('AI assistant', '3 per day', 'Unlimited'),
          const PlanComparisonRow('Monthly AI report', null, ''),
          const PlanComparisonRow('Export data (CSV)', null, ''),
          const PlanComparisonRow('Premium themes', null, ''),
        ];
  }
}
