import 'package:personal_finance/core/security/security_preferences.dart';

/// Manages local auth session state and onboarding flag.
///
/// Backed by [SecurityPreferences] (platform secure enclave) instead of
/// plaintext SharedPreferences, preventing bypass on rooted/jailbroken
/// devices that can modify SharedPreferences.xml / NSUserDefaults.
///
/// IMPORTANT: this is a routing cache only. FirebaseAuth.currentUser is
/// always the authoritative source — never grant data access based solely
/// on this flag.
class LocalAuthService {
  Future<bool> isFirstTime() => SecurityPreferences.getOnboardingComplete()
      .then((complete) => !complete);

  Future<void> completeOnboarding() =>
      SecurityPreferences.setOnboardingComplete();

  Future<bool> isLoggedIn() => SecurityPreferences.getIsLoggedIn();

  Future<void> login() => SecurityPreferences.setLoggedIn(true);

  Future<void> logout() => SecurityPreferences.setLoggedIn(false);
}
