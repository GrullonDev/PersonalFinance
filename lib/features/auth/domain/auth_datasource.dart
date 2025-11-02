import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:shared_preferences/shared_preferences.dart';

/// Interfaz abstracta para servicios de autenticación.
///
/// Define los métodos requeridos para autenticación con proveedores externos
/// como Google y Apple, así como para el cierre de sesión.
abstract class AuthDataSource {
  /// Inicia sesión usando Google Sign-In.
  Future<void> signInWithGoogle();

  /// Inicia sesión usando Apple Sign-In.
  Future<void> signInWithApple();

  /// Cierra la sesión del usuario actual.
  Future<void> logout();

  /// Registra un usuario utilizando email y contraseña en el proveedor de autenticación.
  ///
  /// Retorna el uid asignado por el proveedor una vez finaliza el registro.
  Future<String> registerWithEmail({
    required String email,
    required String password,
  });

  /// Signs in a user with email and password.
  ///
  /// Returns the Firebase UID if successful.
  /// Throws [FirebaseAuthException] if sign in fails.
  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
}

/// Implementación local de almacenamiento de datos de autenticación.
///
/// Gestiona el estado de autenticación y onboarding usando SharedPreferences
/// para almacenamiento local en el dispositivo.
class AuthLocalDataSource {
  /// Verifica si es la primera vez que el usuario abre la aplicación.
  ///
  /// Returns `true` si es la primera vez, `false` si ya completó el onboarding.
  Future<bool> getIsFirstTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isFirstTime') ?? true;
  }

  /// Marca el onboarding como completado.
  ///
  /// Actualiza el estado local para indicar que el usuario ya no es nuevo.
  Future<void> setNotFirstTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
  }

  /// Verifica si el usuario está autenticado.
  ///
  /// Returns `true` si el usuario está logueado, `false` en caso contrario.
  Future<bool> getIsLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  /// Marca al usuario como autenticado.
  ///
  /// Actualiza el estado local para indicar que el usuario ha iniciado sesión.
  Future<void> setLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  /// Marca al usuario como no autenticado.
  ///
  /// Actualiza el estado local para indicar que el usuario ha cerrado sesión.
  Future<void> setLogout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }
}
