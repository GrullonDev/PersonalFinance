import 'package:flutter/foundation.dart';

/// Runtime environment configuration resolved from --dart-define at build time.
///
/// Usage:
///   Development (default):
///     flutter run
///
///   Production:
///     flutter run  --dart-define=APP_ENV=production
///     flutter build ios --dart-define=APP_ENV=production
///     flutter build apk --dart-define=APP_ENV=production
///
/// CI/CD example (GitHub Actions):
///   flutter build ios \
///     --dart-define=APP_ENV=production \
///     --release
///
/// The compile-time constant is baked into the binary — no secrets are
/// embedded. Use this to toggle logging, analytics, and crash reporting
/// behaviour between environments.
class AppConfig {
  AppConfig._();

  /// Current environment. Defaults to 'development' so that running
  /// `flutter run` without any flags works out-of-the-box.
  static const String _env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// If APP_ENV is explicitly set to production, or we are building in release mode,
  /// we run in production.
  static bool get isProduction => _env == 'production' || kReleaseMode;
  static bool get isDevelopment => !isProduction;

  /// Human-readable label shown in debug banners and log tags.
  static String get environmentLabel =>
      isProduction ? 'Production' : 'Development';

  /// Firebase project ID resolved for the active environment.
  static String get firebaseProjectId =>
      isProduction ? 'personalfinance-prod' : 'personalfinancedev-e972f';

  /// When true, verbose logging and debug overlays are enabled.
  /// In production this is always false regardless of kDebugMode.
  static bool get verboseLogging => isDevelopment;
}
