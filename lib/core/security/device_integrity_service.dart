import 'package:flutter/foundation.dart';
// import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class DeviceIntegrityService {
  Future<bool> isDeviceSafe() async {
    try {
      /* final isJailbroken = await FlutterJailbreakDetection.jailbroken;
      final isDeveloperMode = await FlutterJailbreakDetection.developerMode;
      return !isJailbroken && !isDeveloperMode; */
      return true;
    } catch (e) {
      // Si no podemos verificar la integridad, por seguridad bloqueamos.
      debugPrint('DeviceIntegrity check failed: $e');
      return false;
    }
  }
}
