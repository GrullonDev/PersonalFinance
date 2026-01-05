import 'dart:io';
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

  static bool _isGoogleSignInInitialized = false;

  @override
  Future<User?> signInWithGoogle() async {
    try {
      if (!_isGoogleSignInInitialized) {
        if (Platform.isAndroid) {
          await GoogleSignIn.instance.initialize(
            serverClientId: AuthConfig.googleWebClientId,
          );
        } else {
          await GoogleSignIn.instance.initialize();
        }
        _isGoogleSignInInitialized = true;
      }

      final GoogleSignInAccount googleUser;
      try {
        googleUser = await GoogleSignIn.instance.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          return null;
        }
        rethrow;
      } catch (e) {
        // Handle other potential errors during authentication
        rethrow;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      // Note: accessToken is not available in google_sign_in 7.x authentication object
      // and typically not required for Firebase Auth with OIDC.
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
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
  Future<void> logout() async {
    try {
      if (!_isGoogleSignInInitialized) {
        await GoogleSignIn.instance.initialize();
        _isGoogleSignInInitialized = true;
      }
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore if google sign in fails to sign out (e.g. not initialized)
    }
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
