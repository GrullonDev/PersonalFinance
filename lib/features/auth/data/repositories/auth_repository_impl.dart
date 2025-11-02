import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/features/auth/data/datasources/auth_backend_datasource.dart';
import 'package:personal_finance/features/auth/data/models/request/login_user_request.dart';
import 'package:personal_finance/features/auth/data/models/response/login_user_response.dart';
import 'package:personal_finance/features/auth/data/models/request/register_user_request.dart';
import 'package:personal_finance/features/auth/data/models/response/register_user_response.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:personal_finance/features/auth/domain/auth_failure.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/data/models/request/recover_password_request.dart';
import 'package:personal_finance/features/auth/data/models/request/refresh_token_request.dart';
import 'package:personal_finance/features/auth/data/models/request/reset_password_request.dart';
import 'package:personal_finance/features/auth/data/models/response/refresh_token_response.dart';
import 'package:personal_finance/features/auth/data/models/response/current_user_response.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._firebaseDataSource, this._backendDataSource);

  final AuthDataSource _firebaseDataSource;
  final AuthBackendDataSource _backendDataSource;

  @override
  Future<void> signInWithGoogle() => _firebaseDataSource.signInWithGoogle();

  @override
  Future<void> signInWithApple() => _firebaseDataSource.signInWithApple();

  @override
  Future<void> logout() => _firebaseDataSource.logout();

  @override
  Future<Either<AuthFailure, Unit>> recoverPassword(String email) async {
    try {
      await _backendDataSource.recoverPassword(
        RecoverPasswordRequest(email: email),
      );
      return right(unit);
    } on ApiException catch (e) {
      return left(AuthFailure(message: e.message));
    } catch (e) {
      return left(
        const AuthFailure(
          message:
              'Ocurrió un error inesperado. Por favor, intente nuevamente.',
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
    try {
      await _backendDataSource.resetPassword(
        ResetPasswordRequest(
          token: token,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ),
      );
      return right(unit);
    } on ApiException catch (e) {
      return left(AuthFailure(message: e.message));
    } catch (e) {
      return left(
        const AuthFailure(
          message:
              'Ocurrió un error inesperado. Por favor, intente nuevamente.',
        ),
      );
    }
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

      final RegisterUserResponse response = await _backendDataSource
          .registerUser(request.copyWith(firebaseUid: firebaseUid));
      return Right<AuthFailure, RegisterUserResponse>(response);
    } on FirebaseAuthException catch (e) {
      return Left<AuthFailure, RegisterUserResponse>(
        AuthFailure(
          message: e.message ?? 'Error al registrar usuario en Firebase.',
        ),
      );
    } on ApiException catch (e) {
      return Left<AuthFailure, RegisterUserResponse>(
        AuthFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Left<AuthFailure, RegisterUserResponse>(
        AuthFailure(message: 'Error inesperado al registrar usuario: $e'),
      );
    }
  }

  @override
  Future<Either<AuthFailure, LoginUserResponse>> loginUser(
    LoginUserRequest request,
  ) async {
    try {
      // First authenticate with Firebase and get the UID
      final String firebaseUid = await _firebaseDataSource
          .signInWithEmailAndPassword(
            email: request.email,
            password: request.password,
          );

      // Then get the JWT token from our backend, including the Firebase UID
      final LoginUserResponse response = await _backendDataSource.loginUser(
        request.copyWith(firebaseUid: firebaseUid),
      );
      return Right<AuthFailure, LoginUserResponse>(response);
    } on FirebaseAuthException catch (e) {
      return Left<AuthFailure, LoginUserResponse>(
        AuthFailure(
          message: e.message ?? 'Error al iniciar sesión con Firebase.',
        ),
      );
    } on ApiException catch (e) {
      return Left<AuthFailure, LoginUserResponse>(
        AuthFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Left<AuthFailure, LoginUserResponse>(
        AuthFailure(message: 'Error inesperado al iniciar sesión: $e'),
      );
    }
  }

  @override
  Future<Either<AuthFailure, RefreshTokenResponse>> refreshToken(
    String refreshToken,
  ) async {
    try {
      final RefreshTokenResponse response = await _backendDataSource
          .refreshToken(RefreshTokenRequest(refreshToken: refreshToken));
      return right(response);
    } on ApiException catch (e) {
      return left(AuthFailure(message: e.message));
    } catch (e) {
      return left(
        const AuthFailure(message: 'Error al actualizar el token de acceso'),
      );
    }
  }

  @override
  Future<Either<AuthFailure, CurrentUserResponse>> getCurrentUser() async {
    try {
      final CurrentUserResponse response =
          await _backendDataSource.getCurrentUser();
      return right(response);
    } on ApiException catch (e) {
      return left(AuthFailure(message: e.message));
    } catch (e) {
      return left(
        const AuthFailure(
          message: 'Error al obtener la información del usuario',
        ),
      );
    }
  }
}
