import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:dartz/dartz.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:personal_finance/features/auth/data/models/response/refresh_token_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/features/auth/data/local_auth_service.dart';
import 'package:personal_finance/features/auth/data/models/request/login_user_request.dart';
import 'package:personal_finance/features/auth/data/models/request/register_user_request.dart';
import 'package:personal_finance/features/auth/data/models/response/current_user_response.dart';
import 'package:personal_finance/features/auth/data/models/response/login_user_response.dart';
import 'package:personal_finance/features/auth/data/models/response/register_user_response.dart';
import 'package:personal_finance/features/auth/domain/auth_failure.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.authRepository}) {
    _init();
  }

  final AuthRepository authRepository;

  Future<void> _init() async {
    await _loadAuthData();
    if (isAuthenticated) {
      await _refreshTokenIfNeeded();
      await loadCurrentUser();
    }
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  CurrentUserResponse? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiration;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;
  CurrentUserResponse? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated =>
      _accessToken != null &&
      _tokenExpiration != null &&
      _tokenExpiration!.isAfter(DateTime.now());

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      await authRepository.signInWithGoogle();
      await LocalAuthService().login();
      _setLoading(false);
      _setError(null);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    _setLoading(true);
    try {
      await authRepository.signInWithApple();
      await LocalAuthService().login();
      _setLoading(false);
      _setError(null);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await LocalAuthService().logout();
    await authRepository.logout();
    _clearAuthData();
    notifyListeners();
  }

  Future<bool> _refreshTokenIfNeeded() async {
    if (_refreshToken == null || _tokenExpiration == null) {
      return false;
    }

    // Refresh token if it's about to expire (within 5 minutes)
    if (_tokenExpiration!.difference(DateTime.now()).inMinutes < 5) {
      try {
        _isLoading = true;
        notifyListeners();

        final Either<AuthFailure, RefreshTokenResponse> result =
            await authRepository.refreshToken(_refreshToken!);

        return result.fold(
          (AuthFailure failure) {
            // If refresh fails, clear auth data
            _clearAuthData();
            _errorMessage = failure.message;
            return false;
          },
          (RefreshTokenResponse response) {
            _accessToken = response.accessToken;
            _refreshToken = response.refreshToken;
            if (_accessToken != null) {
              _updateTokenExpiration(_accessToken!);
              _saveAuthData();
              return true;
            }
            return false;
          },
        );
      } catch (e) {
        _errorMessage = 'Failed to refresh session. Please log in again.';
        await _clearAuthData();
        return false;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
    return true;
  }

  Future<void> _updateTokenExpiration(String token) async {
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final dynamic exp = decodedToken['exp'];
      if (exp is int) {
        _tokenExpiration =
            DateTime.fromMillisecondsSinceEpoch(
              exp * 1000,
              isUtc: true,
            ).toLocal();
      } else if (exp is double) {
        _tokenExpiration =
            DateTime.fromMillisecondsSinceEpoch(
              (exp * 1000).toInt(),
              isUtc: true,
            ).toLocal();
      } else {
        _tokenExpiration = null;
      }
    } catch (e) {
      _tokenExpiration = null;
    }
  }

  Future<void> _saveAuthData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString('access_token', _accessToken!);
      } else {
        await prefs.remove('access_token');
      }

      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      } else {
        await prefs.remove('refresh_token');
      }

      if (_tokenExpiration != null) {
        await prefs.setString(
          'token_expiry',
          _tokenExpiration!.toIso8601String(),
        );
      } else {
        await prefs.remove('token_expiry');
      }

      if (_currentUser != null) {
        await prefs.setString(
          'current_user',
          jsonEncode(_currentUser!.toJson()),
        );
      } else {
        await prefs.remove('current_user');
      }
    } catch (e) {
      // If there's an error saving auth data, clear everything
      await _clearAuthData();
    }
  }

  Future<void> _loadAuthData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');

      final String? expiryString = prefs.getString('token_expiry');
      if (expiryString != null) {
        _tokenExpiration = DateTime.parse(expiryString);
      }

      final String? userJson = prefs.getString('current_user');
      if (userJson != null) {
        _currentUser = CurrentUserResponse.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      // If there's an error loading auth data, clear everything
      await _clearAuthData();
    }
  }

  Future<void> _clearAuthData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('token_expiry');
      await prefs.remove('current_user');

      _accessToken = null;
      _refreshToken = null;
      _tokenExpiration = null;
      _currentUser = null;

      notifyListeners();
    } catch (e) {
      // Ignore errors during cleanup
    }
  }

  Future<Either<AuthFailure, Unit>> recoverPassword(String email) async {
    _setLoading(true);
    try {
      final Either<AuthFailure, Unit> result = await authRepository
          .recoverPassword(email);
      _setLoading(false);
      return result;
    } on AuthFailure catch (e) {
      _setLoading(false);
      return left(e);
    } catch (e) {
      _setLoading(false);
      return left(
        const AuthFailure(
          message:
              'Ocurrió un error inesperado. Por favor, intente nuevamente.',
        ),
      );
    }
  }

  Future<Either<AuthFailure, Unit>> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    try {
      final Either<AuthFailure, Unit> result = await authRepository
          .resetPassword(
            token: token,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          );
      _setLoading(false);
      return result;
    } on AuthFailure catch (e) {
      _setLoading(false);
      return left(e);
    } catch (e) {
      _setLoading(false);
      return left(
        const AuthFailure(
          message:
              'Ocurrió un error inesperado. Por favor, intente nuevamente.',
        ),
      );
    }
  }

  Future<Either<AuthFailure, RegisterUserResponse>> registerUser(
    RegisterUserRequest request,
  ) async {
    _setLoading(true);
    try {
      final Either<AuthFailure, RegisterUserResponse> result =
          await authRepository.registerUser(request);
      result.fold(
        (AuthFailure failure) => _setError(failure.message),
        (_) => _setError(null),
      );
      return result;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<Either<AuthFailure, CurrentUserResponse>> loadCurrentUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ensure we have a valid token
      if (!isAuthenticated) {
        final bool refreshed = await _refreshTokenIfNeeded();
        if (!refreshed) {
          _errorMessage = 'Session expired. Please log in again.';
          notifyListeners();
          return const Left(
            AuthFailure(message: 'Session expired. Please log in again.'),
          );
        }
      }

      final Either<AuthFailure, CurrentUserResponse> result =
          await authRepository.getCurrentUser();
      return result.fold(
        (AuthFailure failure) {
          _errorMessage = failure.message;
          if (failure.message.toLowerCase().contains('expired') ||
              failure.message.toLowerCase().contains('invalid')) {
            _clearAuthData();
          }
          notifyListeners();
          return Left(failure);
        },
        (CurrentUserResponse user) {
          _currentUser = user;
          _saveAuthData();
          notifyListeners();
          return Right(user);
        },
      );
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      await _clearAuthData();
      notifyListeners();
      return const Left(AuthFailure(message: 'An unexpected error occurred'));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Either<AuthFailure, void>> login() async {
    if (!formKey.currentState!.validate()) {
      return const Left(
        AuthFailure(message: 'Please fill in the required fields.'),
      );
    }
    _setLoading(true);
    try {
      final LoginUserRequest loginRequest = LoginUserRequest(
        email: emailController.text,
        password: passwordController.text,
      );

      final Either<AuthFailure, LoginUserResponse> result = await authRepository
          .loginUser(loginRequest);

      return result.fold(
        (AuthFailure failure) {
          // Handle different types of authentication failures
          final String errorMessage;
          bool shouldNavigateToRegister = false;

          if (failure.statusCode == 400 || failure.statusCode == 401) {
            // Invalid credentials
            errorMessage =
                'Correo o contraseña incorrectos. ¿Desea crear una cuenta?';
            shouldNavigateToRegister = true;
          } else if (failure.statusCode == 500) {
            // Server error
            errorMessage =
                'Error en el servidor. Por favor, intente más tarde.';
          } else if (failure.statusCode == 403) {
            // Account not verified
            errorMessage =
                'Su cuenta no ha sido verificada. Por favor, revise su correo.';
          } else if (failure.statusCode == 429) {
            // Too many requests
            errorMessage =
                'Demasiados intentos. Por favor, espere un momento antes de intentar de nuevo.';
          } else if (failure.message.toLowerCase().contains('network')) {
            // Network error
            errorMessage =
                'Error de conexión. Por favor, verifique su conexión a internet.';
          } else {
            // Default error message
            errorMessage =
                failure.message.isNotEmpty
                    ? failure.message
                    : 'Error al iniciar sesión. Por favor, intente nuevamente.';
          }

          _setError(errorMessage);
          return Left(
            AuthFailure(
              message: errorMessage,
              statusCode: failure.statusCode,
              shouldNavigateToRegister: shouldNavigateToRegister,
            ),
          );
        },
        (LoginUserResponse response) async {
          _setError(null);
          _accessToken = response.accessToken;

          await _updateTokenExpiration(response.accessToken);
          await _saveAuthData();
          await loadCurrentUser();
          return const Right(null);
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return Left(AuthFailure(message: e.toString()));
    } finally {
      _setLoading(false);
    }
  }
}
