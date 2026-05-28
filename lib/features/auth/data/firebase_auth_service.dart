import 'dart:io';
import 'package:flutter/services.dart';
import 'package:personal_finance/core/config/auth_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';

/// Implementación de AuthDataSource usando Firebase Authentication.
///
/// Proporciona métodos para autenticación con Google, Apple y cierre de sesión
/// utilizando Firebase Auth como backend de autenticación.
class FirebaseAuthService implements AuthDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton de google_sign_in v7.x — ya no se instancia manualmente.
  // Lee CLIENT_ID de GoogleService-Info.plist automáticamente en iOS.
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // ── Identidad ──────────────────────────────────────────────────────────────

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  // ── Operaciones ────────────────────────────────────────────────────────────

  @override
  Future<User?> signInWithGoogle() async {
    try {
      if (Platform.isAndroid) {
        return await _signInWithGoogleAndroid();
      } else {
        return await _signInWithGoogleIOS();
      }
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google Sign-In error [${e.code}]: ${e.message}',
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Error en Google Sign-In: $e',
      );
    }
  }

  // Android: flujo web via Chrome Custom Tab.
  // No requiere SHA-1 registrado — usa el Web OAuth client (client_type 3).
  Future<User?> _signInWithGoogleAndroid() async {
    final GoogleAuthProvider googleProvider =
        GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
    final UserCredential userCredential = await _auth.signInWithProvider(
      googleProvider,
    );
    return userCredential.user;
  }

  // iOS: flujo nativo con selector de cuenta de Google (google_sign_in v7.x).
  // authenticate() abre el selector nativo; authentication es getter síncrono.
  Future<User?> _signInWithGoogleIOS() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final String? idToken = googleUser.authentication.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google no devolvió un token de autenticación.',
      );
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );
    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );
    return userCredential.user;
  }

  @override
  Future<void> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions:
            Platform.isAndroid
                ? WebAuthenticationOptions(
                  clientId: AuthConfig.appleServiceId,
                  redirectUri: Uri.parse(AuthConfig.appleRedirectUri),
                )
                : null,
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await _auth.signInWithCredential(credential);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-failed',
        message: 'Error en Apple Sign-In: $e',
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No hay usuario autenticado para eliminar.',
      );
    }
    await user.delete();
  }

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  @override
  Future<String> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final UserCredential userCredential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password);

    if (userCredential.user != null && !userCredential.user!.emailVerified) {
      await userCredential.user!.sendEmailVerification();
    }
    if (userCredential.user?.uid == null) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'No se pudo obtener el uid del usuario de Firebase.',
      );
    }
    return userCredential.user!.uid;
  }

  @override
  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final UserCredential userCredential = await _auth
        .signInWithEmailAndPassword(email: email, password: password);

    if (userCredential.user?.uid == null) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message:
            'No se pudo obtener el UID del usuario de Firebase después del inicio de sesión.',
      );
    }

    return userCredential.user!.uid;
  }
}
