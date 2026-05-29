import 'package:firebase_analytics/firebase_analytics.dart';

class SecurityLogger {
  SecurityLogger({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  Future<void> logAuthFailure(String reason) async {
    try {
      await _analytics.logEvent(
        name: 'security_auth_failure',
        parameters: {
          'reason': reason,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (_) {}
  }

  Future<void> logSuspiciousActivity(String type) async {
    try {
      await _analytics.logEvent(
        name: 'security_suspicious',
        parameters: {
          'type': type,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (_) {}
  }
}
