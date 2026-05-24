import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class DeviceIntegrityService {
  Future<bool> isDeviceSafe() async {
    try {
      final isJailbroken = await FlutterJailbreakDetection.jailbroken;
      final isDeveloperMode = await FlutterJailbreakDetection.developerMode;
      return !isJailbroken && !isDeveloperMode;
    } catch (_) {
      // Si la plataforma no está soportada o hay un error, por precaución
      // permitimos continuar pero registrando el fallo si fuera necesario.
      return true;
    }
  }
}
