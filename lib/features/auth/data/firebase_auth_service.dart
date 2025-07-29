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

  Future<void> registerUser(String email, String password) async {
    final UserCredential userCredential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password);

    // Enviar correo de verificación
    if (userCredential.user != null && !userCredential.user!.emailVerified) {
      await userCredential.user!.sendEmailVerification();
    }
  }

  /// Inicia sesión con email o nombre de usuario
  Future<User?> loginUser(String emailOrUsername, String password) async {
    try {
      String email = emailOrUsername;
      
      // Si no contiene @, es un username, buscar el email correspondiente
      if (!emailOrUsername.contains('@')) {
        email = await _getEmailFromUsername(emailOrUsername);
      }

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      // Si falla, intentar como email directo en caso de error en la búsqueda
      if (!emailOrUsername.contains('@')) {
        throw Exception('Usuario no encontrado');
      }
      rethrow;
    }
  }

  /// Busca el email asociado a un nombre de usuario
  Future<String> _getEmailFromUsername(String username) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('userProfiles')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Usuario no encontrado');
      }

      final Map<String, dynamic> userData = 
          querySnapshot.docs.first.data() as Map<String, dynamic>;
      
      return userData['email'] as String;
    } catch (e) {
      throw Exception('Error al buscar usuario: ${e.toString()}');
    }
  }

  /// Verifica si un nombre de usuario ya existe
  Future<bool> isUsernameExists(String username) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('userProfiles')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
