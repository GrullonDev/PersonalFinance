import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar autenticación local usando SharedPreferences.
/// 
/// Gestiona el estado de autenticación del usuario y el onboarding
/// almacenando datos localmente en el dispositivo.
class LocalAuthService {
  /// Verifica si es la primera vez que el usuario abre la aplicación.
  /// 
  /// Returns `true` si es la primera vez, `false` si ya completó el onboarding.
  Future<bool> isFirstTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isFirstTime') ?? true;
  }

  /// Marca el onboarding como completado.
  /// 
  /// Actualiza el estado local para indicar que el usuario ya no es nuevo.
  Future<void> completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
  }

  /// Verifica si el usuario está autenticado.
  /// 
  /// Returns `true` si el usuario está logueado, `false` en caso contrario.
  Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  /// Marca al usuario como autenticado.
  /// 
  /// Actualiza el estado local para indicar que el usuario ha iniciado sesión.
  Future<void> login() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  /// Marca al usuario como no autenticado.
  /// 
  /// Actualiza el estado local para indicar que el usuario ha cerrado sesión.
  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }
}
