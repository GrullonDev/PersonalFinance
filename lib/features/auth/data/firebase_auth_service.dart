import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Implementación de AuthDataSource usando Firebase Authentication.
/// 
/// Proporciona métodos para autenticación con Google, Apple y cierre de sesión
/// utilizando Firebase Auth como backend de autenticación.
class FirebaseAuthService implements AuthDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in aborted');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user != null) {
        await _saveUser(user);
      }
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  @override
  Future<void> signInWithApple() async {
    if (!Platform.isIOS) {
      throw Exception('Apple Sign-In no soportado en esta plataforma');
    }
    try {
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
      final UserCredential userCredential =
          await _auth.signInWithCredential(oauthCredential);
      final User? user = userCredential.user;
      if (user != null) {
        await _saveUser(user);
      }
    } catch (e) {
      throw Exception('Error al iniciar sesión con Apple: $e');
    }
  }

  @override
  Future<void> logout() async {
    await Future.wait<void>(<Future<void>>[
      _auth.signOut(),
      GoogleSignIn.instance.disconnect(),
    ]);
  }

  Future<void> _saveUser(User user) async {
    final DocumentReference<Map<String, dynamic>> ref =
        _firestore.collection('users').doc(user.uid);
    await ref.set(<String, dynamic>{
      'uid': user.uid,
      'name': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : null,
    },
        SetOptions(merge: true));
  }
}
