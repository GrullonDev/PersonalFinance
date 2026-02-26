import 'package:equatable/equatable.dart';

class NotificationPreferences extends Equatable {
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

  const NotificationPreferences({
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

  NotificationPreferences copyWith({
    bool? emailEnabled,
    bool? pushEnabled,
    bool? marketingEnabled,
    String? emailFrequency,
    bool? servicesDueEnabled,
    String? servicesDueTiming,
    bool? budgetAlertsEnabled,
    double? budgetThreshold,
    bool? savingsGoalsEnabled,
    bool? weeklySummaryEnabled,
  }) => NotificationPreferences(
    emailEnabled: emailEnabled ?? this.emailEnabled,
    pushEnabled: pushEnabled ?? this.pushEnabled,
    marketingEnabled: marketingEnabled ?? this.marketingEnabled,
    emailFrequency: emailFrequency ?? this.emailFrequency,
    servicesDueEnabled: servicesDueEnabled ?? this.servicesDueEnabled,
    servicesDueTiming: servicesDueTiming ?? this.servicesDueTiming,
    budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
    budgetThreshold: budgetThreshold ?? this.budgetThreshold,
    savingsGoalsEnabled: savingsGoalsEnabled ?? this.savingsGoalsEnabled,
    weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
  );

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
