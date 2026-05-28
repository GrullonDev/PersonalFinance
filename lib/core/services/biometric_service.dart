import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device has biometric hardware and if it's available
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Get a list of available biometrics (Face, Fingerprint, etc)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// Check if the user has enrolled any biometrics
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;

      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on LocalAuthException {
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Trigger native biometric authentication
  Future<bool> authenticate({
    required String localizedReason,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autenticación biométrica',
            cancelButton: 'No, gracias',
          ),
          IOSAuthMessages(
            cancelButton: 'No, gracias',
          ),
        ],
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: stickyAuth,
      );
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.noCredentialsSet ||
          e.code == LocalAuthExceptionCode.noBiometricsEnrolled) {
        // Handle as not enrolled/no credentials
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
