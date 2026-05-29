import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:personal_finance/core/security/security_preferences.dart';

/// Interfaz abstracta para servicios de autenticación.
///
/// Define los métodos requeridos para autenticación con proveedores externos
/// como Google y Apple, así como para el cierre de sesión.
abstract class AuthDataSource {
  // ── Identidad ──────────────────────────────────────────────────────────────

  /// UID del usuario actualmente autenticado, o `null` si no hay sesión activa.
  /// Sincrónico: usa el estado en memoria del SDK de auth.
  String? get currentUserId;

  /// Stream que emite el UID cada vez que cambia el estado de autenticación.
  /// Emite `null` cuando el usuario cierra sesión.
  /// Emite el UID real tan pronto como el SDK restaura la sesión persistida
  /// (resuelve la race condition de `currentUser` en el arranque).
  Stream<String?> get authStateChanges;

  // ── Operaciones ────────────────────────────────────────────────────────────
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

  /// Permanently deletes the Firebase Auth account of the current user.
  ///
  /// Requires recent authentication — callers must reauthenticate before
  /// invoking this if the session is older than a few minutes (Firebase
  /// will throw `requires-recent-login`).
  ///
  /// Throws [FirebaseAuthException] on failure.
  Future<void> deleteAccount();
}

/// Local storage for auth session routing state.
///
/// Backed by [SecurityPreferences] (platform secure enclave). Not a
/// replacement for FirebaseAuth — used only for routing decisions.
class AuthLocalDataSource {
  Future<bool> getIsFirstTime() async =>
      !(await SecurityPreferences.getOnboardingComplete());

  Future<void> setNotFirstTime() => SecurityPreferences.setOnboardingComplete();

  Future<bool> getIsLoggedIn() => SecurityPreferences.getIsLoggedIn();

  Future<void> setLogin() => SecurityPreferences.setLoggedIn(value: true);

  Future<void> setLogout() => SecurityPreferences.setLoggedIn(value: false);
}
