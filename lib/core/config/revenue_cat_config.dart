/// RevenueCat API keys — reemplaza con tus claves reales del dashboard de RevenueCat.
/// iOS key: App Store Connect → RevenueCat dashboard → Apps → [tu app] → API Keys
/// Android key: Google Play Console → RevenueCat dashboard → Apps → [tu app] → API Keys
class RevenueCatConfig {
  static const String appleApiKey = 'appl_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
  static const String googleApiKey = 'goog_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

  /// Identificador del entitlement en RevenueCat ("pro" debe coincidir con el
  /// entitlement creado en el dashboard de RevenueCat).
  static const String entitlementId = 'pro';

  /// Identificador del producto mensual en App Store / Google Play.
  static const String monthlyProductId = 'pf_pro_monthly';
}
