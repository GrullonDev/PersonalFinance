import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';

/// Implementación de AuthDataSource usando Firebase Authentication.
///
/// Proporciona métodos para autenticación con Google, Apple y cierre de sesión
/// utilizando Firebase Auth como backend de autenticación.
class FirebaseAuthService implements AuthDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<User?> signInWithGoogle() async {
    throw UnimplementedError('Autenticación con Google eliminada.');
  }

  @override
  Future<void> signInWithApple() async {
    throw UnimplementedError('Autenticación con Apple eliminada.');
  }

  @override
  Future<void> logout() async {
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
