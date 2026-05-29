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
  static const Map<PlanFeature, ({String title, String description})> labels = {
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
}
