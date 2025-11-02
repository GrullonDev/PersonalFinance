import 'package:dartz/dartz.dart';
import 'package:personal_finance/features/auth/data/models/request/register_user_request.dart';
import 'package:personal_finance/features/auth/data/models/response/register_user_response.dart';
import 'package:personal_finance/features/auth/data/models/request/login_user_request.dart';
import 'package:personal_finance/features/auth/data/models/response/login_user_response.dart';
import 'package:personal_finance/features/auth/domain/auth_failure.dart';
import 'package:personal_finance/features/auth/data/models/response/refresh_token_response.dart';
import 'package:personal_finance/features/auth/data/models/response/current_user_response.dart';

// Auth repository interface
abstract class AuthRepository {
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> logout();
  Future<Either<AuthFailure, RegisterUserResponse>> registerUser(
    RegisterUserRequest request,
  );
  
  Future<Either<AuthFailure, LoginUserResponse>> loginUser(
    LoginUserRequest request,
  );
  
  Future<Either<AuthFailure, Unit>> recoverPassword(String email);
  
  Future<Either<AuthFailure, Unit>> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  });

  Future<Either<AuthFailure, RefreshTokenResponse>> refreshToken(String refreshToken);
  
  Future<Either<AuthFailure, CurrentUserResponse>> getCurrentUser();
}
