import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class DeviceService {
  static const String _deviceIdKey = 'device_unique_id';
  String? _cachedDeviceId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedDeviceId = prefs.getString(_deviceIdKey);

    if (_cachedDeviceId == null) {
      _cachedDeviceId = _generateId();
      await prefs.setString(_deviceIdKey, _cachedDeviceId!);
    }
  }

  String get deviceId => _cachedDeviceId ?? 'unknown_device';

  String _generateId() {
    // Basic unique ID generation based on timestamp and platform
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = Platform.operatingSystem;
    return '${platform}_$timestamp';
  }
}
