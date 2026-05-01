import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single source of truth for all security-sensitive boolean flags.
///
/// Stores values in the platform secure enclave:
///   - Android: EncryptedSharedPreferences backed by the hardware Keystore
///   - iOS: Keychain with first_unlock accessibility
///
/// A rooted/jailbroken device that can tamper with SharedPreferences.xml
/// or NSUserDefaults cannot reach these values.
class SecurityPreferences {
  SecurityPreferences._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Key constants ─────────────────────────────────────────────────────────
  static const _keyBiometric = 'biometric_enabled';
  static const _keyAppLock = 'app_lock_enabled';
  static const _keyLoggedIn = 'auth_is_logged_in';
  static const _keyOnboarding = 'auth_onboarding_complete';

  // ── Biometrics ────────────────────────────────────────────────────────────

  static Future<bool> getBiometricEnabled() async {
    final v = await _storage.read(key: _keyBiometric);
    return v == 'true';
  }

  static Future<void> setBiometricEnabled(bool value) =>
      _storage.write(key: _keyBiometric, value: value.toString());

  // ── App lock ──────────────────────────────────────────────────────────────

  static Future<bool> getAppLockEnabled() async {
    final v = await _storage.read(key: _keyAppLock);
    return v == 'true';
  }

  static Future<void> setAppLockEnabled(bool value) =>
      _storage.write(key: _keyAppLock, value: value.toString());

  // ── Auth session state ────────────────────────────────────────────────────
  // NOTE: this is a lightweight cache for routing decisions only.
  // Firebase Auth SDK is the authoritative source of truth. Never use this
  // flag to grant access to sensitive data — always verify via FirebaseAuth.

  static Future<bool> getIsLoggedIn() async {
    final v = await _storage.read(key: _keyLoggedIn);
    return v == 'true';
  }

  static Future<void> setLoggedIn(bool value) =>
      _storage.write(key: _keyLoggedIn, value: value.toString());

  // ── Onboarding ────────────────────────────────────────────────────────────

  static Future<bool> getOnboardingComplete() async {
    final v = await _storage.read(key: _keyOnboarding);
    return v == 'true';
  }

  static Future<void> setOnboardingComplete() =>
      _storage.write(key: _keyOnboarding, value: 'true');
}
