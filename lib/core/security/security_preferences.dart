import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists security flags (biometric_enabled, app_lock_enabled) in the
/// platform's secure enclave instead of plaintext SharedPreferences.
///
/// On Android this uses EncryptedSharedPreferences backed by the hardware
/// Keystore. On iOS it uses the Keychain. A rooted/jailbroken device that
/// can tamper with SharedPreferences.xml cannot reach these values.
class SecurityPreferences {
  SecurityPreferences._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyBiometric = 'biometric_enabled';
  static const _keyAppLock = 'app_lock_enabled';

  static Future<bool> getBiometricEnabled() async {
    final v = await _storage.read(key: _keyBiometric);
    return v == 'true';
  }

  static Future<void> setBiometricEnabled(bool value) =>
      _storage.write(key: _keyBiometric, value: value.toString());

  static Future<bool> getAppLockEnabled() async {
    final v = await _storage.read(key: _keyAppLock);
    return v == 'true';
  }

  static Future<void> setAppLockEnabled(bool value) =>
      _storage.write(key: _keyAppLock, value: value.toString());
}
