import 'package:personal_finance/core/security/security_preferences.dart';

/// Gestiona el estado de sesión local y el flag de onboarding.
///
/// Usa [SecurityPreferences] (enclave seguro) en lugar de SharedPreferences
/// para prevenir bypass en dispositivos rooteados / jailbroken.
///
/// IMPORTANTE: es solo una caché de routing. FirebaseAuth.currentUser siempre
/// es la fuente autoritativa — nunca conceder acceso a datos solo por este flag.
class LocalAuthService {
  Future<bool> isFirstTime() =>
      SecurityPreferences.getOnboardingComplete().then((complete) => !complete);

  Future<void> completeOnboarding() =>
      SecurityPreferences.setOnboardingComplete();

  Future<bool> isLoggedIn() => SecurityPreferences.getIsLoggedIn();

  Future<void> login() => SecurityPreferences.setLoggedIn(value: true);

  Future<void> logout() => SecurityPreferences.setLoggedIn(value: false);
}
