import 'package:equatable/equatable.dart';

class NotificationPreferencesModel extends Equatable {
  final bool emailEnabled;
  final bool pushEnabled;
  final bool marketingEnabled;

  const NotificationPreferencesModel({
    required this.emailEnabled,
    required this.pushEnabled,
    required this.marketingEnabled,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) =>
      NotificationPreferencesModel(
        emailEnabled: json['email_enabled'] == true,
        pushEnabled: json['push_enabled'] == true,
        marketingEnabled: json['marketing_enabled'] == true,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email_enabled': emailEnabled,
    'push_enabled': pushEnabled,
    'marketing_enabled': marketingEnabled,
  };

  @override
  List<Object?> get props => <Object?>[
    emailEnabled,
    pushEnabled,
    marketingEnabled,
  ];
}
