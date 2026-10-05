import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:personal_finance/core/services/update_policy.dart';

/// Resultado de la verificación de actualización.
class UpdateCheck {
  const UpdateCheck({
    required this.kind,
    required this.url,
    required this.latest,
    this.notes = '',
  });

  static const UpdateCheck none = UpdateCheck(
    kind: UpdateKind.none,
    url: '',
    latest: AppVersion('', 0),
  );

  final UpdateKind kind;
  final String url;
  final AppVersion latest;
  final String notes;
}

class VersionService {
  static const String _testFlightUrl =
      'https://testflight.apple.com/join/2DYkgW28';
  static const String _playInternalTestUrl =
      'https://play.google.com/apps/internaltest/4701744229965287282';

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  late PackageInfo _packageInfo;

  PackageInfo get packageInfo => _packageInfo;

  Future<void> init() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await _remoteConfig.setDefaults(<String, dynamic>{
        'min_app_version': '1.0.0',
        'store_url_android':
            'https://play.google.com/store/apps/details?id=com.grullondev.personal_finance',
        'store_url_ios': '',
        // Aviso de nueva versión (se edita en Firebase Remote Config al
        // publicar). Formato: "1.2.3+4" (versión + build). Vacío = sin aviso.
        'update_latest_ios': '',
        'update_latest_android': '',
        // Por debajo de esta versión la app obliga a actualizar.
        'update_min_ios': '',
        'update_min_android': '',
        // Mientras la app esté en pruebas, los enlaces llevan a TestFlight y
        // a la prueba interna de Google Play.
        'update_url_ios': _testFlightUrl,
        'update_url_android': _playInternalTestUrl,
        'update_notes': '',
      });
      await _remoteConfig.fetchAndActivate();

      // Check for Android in-app update
      if (Platform.isAndroid) {
        await _performAndroidUpdate();
      }
    } catch (e) {
      // If fetching fails, we continue with defaults
      developer.log('Error initializing Remote Config: $e');
    }
  }

  Future<void> _performAndroidUpdate() async {
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Enforce immediate update if allowed
        if (updateInfo.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          // Fallback to flexible if immediate not allowed but update available
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      developer.log('Error in Android In-App Update: $e');
    }
  }

  Future<bool> isUpdateRequired() async {
    try {
      developer.log(
        'App version: ${_packageInfo.version}+${_packageInfo.buildNumber}',
      );
      final String currentVersion = _packageInfo.version;
      final String minRequiredVersion = _remoteConfig.getString(
        'min_app_version',
      );

      return _isVersionLower(currentVersion, minRequiredVersion);
    } catch (e) {
      developer.log('Error checking update: $e');
      return false;
    }
  }

  bool _isVersionLower(String current, String required) {
    try {
      final List<int> currentParts =
          current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final List<int> requiredParts =
          required.split('.').map((s) => int.tryParse(s) ?? 0).toList();

      final int maxLength =
          currentParts.length > requiredParts.length
              ? currentParts.length
              : requiredParts.length;

      for (int i = 0; i < maxLength; i++) {
        final int currentPart = i < currentParts.length ? currentParts[i] : 0;
        final int requiredPart =
            i < requiredParts.length ? requiredParts[i] : 0;

        if (currentPart < requiredPart) return true;
        if (currentPart > requiredPart) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Compara la versión instalada con la publicada en Remote Config.
  ///
  /// Se vuelve a consultar Remote Config (respetando el intervalo mínimo)
  /// para detectar versiones publicadas mientras la app seguía abierta.
  Future<UpdateCheck> checkForUpdate() async {
    try {
      try {
        await _remoteConfig.fetchAndActivate();
      } catch (_) {}
      final String platform = Platform.isIOS ? 'ios' : 'android';
      final AppVersion installed = AppVersion.parse(
        _packageInfo.version,
        androidBuildToPubspec(int.tryParse(_packageInfo.buildNumber) ?? 0),
      );
      final AppVersion latest = AppVersion.parse(
        _remoteConfig.getString('update_latest_$platform'),
      );
      AppVersion minimum = AppVersion.parse(
        _remoteConfig.getString('update_min_$platform'),
      );
      // Compatibilidad con la clave anterior (sólo versión, sin build).
      final AppVersion legacyMin = AppVersion.parse(minAppVersion);
      if (minimum.isEmpty || minimum < legacyMin) minimum = legacyMin;

      final UpdateKind kind = evaluateUpdate(
        installed: installed,
        latest: latest,
        minimum: minimum,
      );
      if (kind == UpdateKind.none) return UpdateCheck.none;
      return UpdateCheck(
        kind: kind,
        url: updateUrl,
        latest: latest.isEmpty ? minimum : latest,
        notes: _remoteConfig.getString('update_notes'),
      );
    } catch (e) {
      developer.log('Error checking update: $e');
      return UpdateCheck.none;
    }
  }

  /// En Android el versionCode es 1.000.000 + build del pubspec (ver
  /// android/app/build.gradle.kts); se convierte de vuelta para comparar
  /// con lo publicado en Remote Config ("1.2.3+4").
  static int androidBuildToPubspec(int versionCode) =>
      versionCode >= 1000000 ? versionCode - 1000000 : versionCode;

  /// Enlace para actualizar en la plataforma actual.
  String get updateUrl {
    final String url = _remoteConfig.getString(
      Platform.isIOS ? 'update_url_ios' : 'update_url_android',
    );
    if (url.isNotEmpty) return url;
    return Platform.isIOS ? _testFlightUrl : _playInternalTestUrl;
  }

  String get storeUrl => updateUrl;
  String get storeUrlIos => _remoteConfig.getString('store_url_ios');
  String get minAppVersion => _remoteConfig.getString('min_app_version');
}
