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

  // serverClientId (Web Client ID / client_type 3 en google-services.json)
  // permite que el flujo OAuth funcione en Android sin depender del SHA-1
  // del certificado de firma. Mismo ID usado en iOS.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AuthConfig.googleWebClientId,
  );

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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-failed',
          message: 'Google no devolvió un token de autenticación.',
        );
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
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

    // Enviar correo de verificación
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
