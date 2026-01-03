import 'package:equatable/equatable.dart';

class NotificationPreferences extends Equatable {
  final bool emailEnabled;
  final bool pushEnabled;
  final bool marketingEnabled;

  const NotificationPreferences({
    required this.emailEnabled,
    required this.pushEnabled,
    required this.marketingEnabled,
  });

  NotificationPreferences copyWith({
    bool? emailEnabled,
    bool? pushEnabled,
    bool? marketingEnabled,
  }) => NotificationPreferences(
    emailEnabled: emailEnabled ?? this.emailEnabled,
    pushEnabled: pushEnabled ?? this.pushEnabled,
    marketingEnabled: marketingEnabled ?? this.marketingEnabled,
  );

  @override
  List<Object?> get props => <Object?>[
    emailEnabled,
    pushEnabled,
    marketingEnabled,
  ];
}
