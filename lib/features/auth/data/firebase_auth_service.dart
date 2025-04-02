import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:personal_finance/features/auth/domain/auth_datasource.dart';

class FirebaseAuthService implements AuthDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseAuthService() {
    if (Firebase.apps.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_core',
        message: 'Firebase no ha sido inicializado.',
      );
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    if (googleAuth == null) throw Exception('Error al obtener token de Google');

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signInWithFacebook() async {
    final LoginResult loginResult = await FacebookAuth.instance.login();
    final OAuthCredential credential = FacebookAuthProvider.credential(
      loginResult.accessToken!.tokenString,
    );
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signInWithApple() async {
    if (!Platform.isIOS) return;

    final AuthorizationCredentialAppleID appleCredential =
        await SignInWithApple.getAppleIDCredential(
          scopes: <AppleIDAuthorizationScopes>[
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

    final OAuthCredential oauthCredential = OAuthProvider(
      'apple.com',
    ).credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    await _auth.signInWithCredential(oauthCredential);
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }
}
