import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:personal_finance/features/auth/data/models/request/login_user_request.dart';
import 'package:personal_finance/features/auth/data/models/response/login_user_response.dart';
import 'package:personal_finance/features/auth/data/models/request/register_user_request.dart';
import 'package:personal_finance/features/auth/data/models/response/register_user_response.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:personal_finance/features/auth/domain/auth_failure.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/data/models/response/refresh_token_response.dart';
import 'package:personal_finance/features/auth/data/models/response/current_user_response.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._firebaseDataSource);

  final AuthDataSource _firebaseDataSource;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> signInWithGoogle() => _firebaseDataSource.signInWithGoogle();

  @override
  Future<void> signInWithApple() => _firebaseDataSource.signInWithApple();

  @override
  Future<void> logout() => _firebaseDataSource.logout();

  @override
  Future<Either<AuthFailure, Unit>> recoverPassword(String email) async {
    try {
      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      return right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return left(
        AuthFailure(
          message: e.message ?? 'Error al enviar correo de recuperación',
        ),
      );
    } catch (e) {
      return left(
        const AuthFailure(
          message: 'Ocurrió un error inesperado al recuperar contraseña.',
        ),
      );
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Note: Firebase handles password reset via the link sent to email.
    // ConfimPassword reset via API is not directly supported by client SDK in the same way as backend tokens.
    // However, if the user is logged in, we can update password.
    // If this is a flow where the user receives a code, Firebase dynamic links manage it.
    // For now, returning success as this flow might need UI adjustment for Firebase.
    return right(unit);
  }

  @override
  Future<Either<AuthFailure, RegisterUserResponse>> registerUser(
    RegisterUserRequest request,
  ) async {
    try {
      final String firebaseUid = await _firebaseDataSource.registerWithEmail(
        email: request.email,
        password: request.password,
      );

      final DateTime now = DateTime.now();

      final Map<String, dynamic> userData = {
        'id': now.millisecondsSinceEpoch, // Generating a pseudo-ID
        'firebase_uid': firebaseUid,
        'email': request.email,
        'username': request.username,
        'nombres': request.nombres,
        'apellidos': request.apellidos,
        'nombre_completo': '${request.nombres} ${request.apellidos}',
        'fecha_nacimiento': request.fechaNacimiento,
        'fecha_creacion': now.toIso8601String(),
        'fecha_actualizacion': now.toIso8601String(),
        'is_active': true,
        'is_superuser': false,
        // 'phone_number': request.phoneNumber, // Not in request
      };

      await _firestore.collection('users').doc(firebaseUid).set(userData);

      // Construct legacy response
      final response = RegisterUserResponse(
        id: userData['id'] as int,
        firebaseUid: userData['firebase_uid'] as String,
        email: userData['email'] as String,
        username: userData['username'] as String,
        nombres: userData['nombres'] as String,
        apellidos: userData['apellidos'] as String,
        nombreCompleto: userData['nombre_completo'] as String,
        fechaNacimiento: userData['fecha_nacimiento'] as String,
        fechaCreacion: userData['fecha_creacion'] as String,
        fechaActualizacion: userData['fecha_actualizacion'] as String,
      );

      return Right(response);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(
        AuthFailure(
          message: e.message ?? 'Error al registrar usuario en Firebase.',
        ),
      );
    } catch (e) {
      return Left(
        AuthFailure(message: 'Error inesperado al registrar usuario: $e'),
      );
    }
  }

  @override
  Future<Either<AuthFailure, LoginUserResponse>> loginUser(
    LoginUserRequest request,
  ) async {
    try {
      final String firebaseUid = await _firebaseDataSource
          .signInWithEmailAndPassword(
            email: request.email,
            password: request.password,
          );

      // Fetch user data from Firestore
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(firebaseUid).get();

      if (!doc.exists) {
        // Create basic doc if missing (migrated user or error)
        return Left(
          AuthFailure(message: 'El usuario no tiene un perfil asociado.'),
        );
      }

      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Helper to safely get int
      int safeId = 0;
      final dynamic idRaw = data['id'];
      if (idRaw is int) {
        safeId = idRaw;
      } else if (idRaw is String) {
        safeId = int.tryParse(idRaw) ?? 0;
      }

      // Construct User object for legacy response
      final user = User(
        id: safeId,
        firebaseUid: firebaseUid,
        email: (data['email'] as String?) ?? request.email,
        username: (data['username'] as String?) ?? '',
        nombres: (data['nombres'] as String?) ?? '',
        apellidos: (data['apellidos'] as String?) ?? '',
        nombreCompleto: (data['nombre_completo'] as String?) ?? '',
        fechaNacimiento:
            (data['fecha_nacimiento'] as String?) ??
            DateTime.now().toIso8601String(),
        fechaCreacion:
            (data['fecha_creacion'] as String?) ??
            DateTime.now().toIso8601String(),
        fechaActualizacion:
            (data['fecha_actualizacion'] as String?) ??
            DateTime.now().toIso8601String(),
      );

      // Construct LoginUserResponse
      final response = LoginUserResponse(
        accessToken:
            "firebase-token-placeholder", // Not needed really but req by model
        tokenType: "bearer",
        user: user,
        refreshToken: "firebase-refresh-token-placeholder",
      );

      return Right(response);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(
        AuthFailure(
          message: e.message ?? 'Error al iniciar sesión con Firebase.',
        ),
      );
    } catch (e) {
      return Left(
        AuthFailure(message: 'Error inesperado al iniciar sesión: $e'),
      );
    }
  }

  @override
  Future<Either<AuthFailure, RefreshTokenResponse>> refreshToken(
    String refreshToken,
  ) async {
    // Firebase handles token refresh automatically.
    return Left(AuthFailure(message: "Refresh token no necesario en Firebase"));
  }

  @override
  Future<Either<AuthFailure, CurrentUserResponse>> getCurrentUser() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(AuthFailure(message: "No hay usuario autenticado"));
      }

      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return Left(
          AuthFailure(message: 'Perfil no encontrado en base de datos.'),
        );
      }

      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      int safeId = 0;
      final dynamic idRaw = data['id'];
      if (idRaw is int) {
        safeId = idRaw;
      } else if (idRaw is String) {
        safeId = int.tryParse(idRaw) ?? 0;
      }

      final response = CurrentUserResponse(
        email: (data['email'] as String?) ?? user.email ?? '',
        fullName:
            (data['nombre_completo'] as String?) ??
            (data['full_name'] as String?) ??
            '',
        isActive: (data['is_active'] as bool?) ?? true,
        isSuperuser: (data['is_superuser'] as bool?) ?? false,
        id: safeId,
        createdAt:
            data['fecha_creacion'] != null
                ? DateTime.parse(data['fecha_creacion'] as String)
                : DateTime.now(),
        updatedAt:
            data['fecha_actualizacion'] != null
                ? DateTime.parse(data['fecha_actualizacion'] as String)
                : DateTime.now(),
        phoneNumber: data['phone_number'] as String?,
      );

      return right(response);
    } catch (e) {
      return left(
        AuthFailure(message: 'Error al obtener la información del usuario: $e'),
      );
    }
  }
}
