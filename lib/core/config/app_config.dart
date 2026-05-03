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
  static const String _env =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static bool get isProduction => _env == 'production';
  static bool get isDevelopment => !isProduction;

  /// Human-readable label shown in debug banners and log tags.
  static String get environmentLabel =>
      isProduction ? 'Production' : 'Development';

  /// Firebase project ID resolved for the active environment.
  /// Both environments currently point to `personalfinancedev-e972f`.
  /// When a dedicated prod project is created, replace the production value:
  ///   static const String _prodProjectId = 'personalfinance-prod';
  static const String firebaseProjectId = 'personalfinancedev-e972f';

  /// When true, verbose logging and debug overlays are enabled.
  /// In production this is always false regardless of kDebugMode.
  static bool get verboseLogging => isDevelopment;
}
