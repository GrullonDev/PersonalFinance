import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'dart:io';
import 'dart:developer' as developer;

class VersionService {
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

  String get storeUrl => _remoteConfig.getString('store_url_android');
  String get storeUrlIos => _remoteConfig.getString('store_url_ios');
  String get minAppVersion => _remoteConfig.getString('min_app_version');
}
