import 'package:equatable/equatable.dart';

class NotificationPreferencesModel extends Equatable {
  final bool emailEnabled;
  final bool pushEnabled;
  final bool marketingEnabled;
  final String emailFrequency;
  final bool servicesDueEnabled;
  final String servicesDueTiming;
  final bool budgetAlertsEnabled;
  final double budgetThreshold;
  final bool savingsGoalsEnabled;
  final bool weeklySummaryEnabled;

  const NotificationPreferencesModel({
    required this.emailEnabled,
    required this.pushEnabled,
    required this.marketingEnabled,
    this.emailFrequency = 'Semanal',
    this.servicesDueEnabled = true,
    this.servicesDueTiming = '3 días antes',
    this.budgetAlertsEnabled = true,
    this.budgetThreshold = 80.0,
    this.savingsGoalsEnabled = true,
    this.weeklySummaryEnabled = true,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) =>
      NotificationPreferencesModel(
        emailEnabled: json['email_enabled'] == true,
        pushEnabled: json['push_enabled'] == true,
        marketingEnabled: json['marketing_enabled'] == true,
        emailFrequency: json['email_frequency'] as String? ?? 'Semanal',
        servicesDueEnabled: json['services_due_enabled'] as bool? ?? true,
        servicesDueTiming:
            json['services_due_timing'] as String? ?? '3 días antes',
        budgetAlertsEnabled: json['budget_alerts_enabled'] as bool? ?? true,
        budgetThreshold: (json['budget_threshold'] as num?)?.toDouble() ?? 80.0,
        savingsGoalsEnabled: json['savings_goals_enabled'] as bool? ?? true,
        weeklySummaryEnabled: json['weekly_summary_enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email_enabled': emailEnabled,
    'push_enabled': pushEnabled,
    'marketing_enabled': marketingEnabled,
    'email_frequency': emailFrequency,
    'services_due_enabled': servicesDueEnabled,
    'services_due_timing': servicesDueTiming,
    'budget_alerts_enabled': budgetAlertsEnabled,
    'budget_threshold': budgetThreshold,
    'savings_goals_enabled': savingsGoalsEnabled,
    'weekly_summary_enabled': weeklySummaryEnabled,
  };

  @override
  List<Object?> get props => <Object?>[
    emailEnabled,
    pushEnabled,
    marketingEnabled,
    emailFrequency,
    servicesDueEnabled,
    servicesDueTiming,
    budgetAlertsEnabled,
    budgetThreshold,
    savingsGoalsEnabled,
    weeklySummaryEnabled,
  ];
}
