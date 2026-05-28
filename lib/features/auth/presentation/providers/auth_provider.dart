import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

import 'package:dartz/dartz.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:personal_finance/core/services/app_data_cleanup_service.dart';
import 'package:personal_finance/core/security/auth_session_storage.dart';
import 'package:personal_finance/core/services/security_logger.dart';

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
    final bool restored = await syncSessionFromFirebase(notify: false);
    if (restored) {
      await loadCurrentUser();
    }
    notifyListeners();
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
  bool get isAuthenticated {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    return user != null && user.emailVerified;
  }

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
      final result = await authRepository.signInWithGoogle();
      return await result.fold(
        (failure) {
          _setLoading(false);
          _setError(_localizeAuthMessage(failure.message));
          return false;
        },
        (response) async {
          await _handleSuccessfulLogin(response);
          final bool restored = await syncSessionFromFirebase(
            forceRefresh: true,
          );
          if (!restored) {
            _setLoading(false);
            return false;
          }
          await loadCurrentUser();
          await LocalAuthService().login();
          _setLoading(false);
          _setError(null);
          return true;
        },
      );
    } catch (e) {
      _setLoading(false);
      _setError(_localizeAuthMessage(e.toString()));
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    _setLoading(true);
    try {
      final result = await authRepository.signInWithApple();
      return await result.fold(
        (failure) {
          _setLoading(false);
          _setError(_localizeAuthMessage(failure.message));
          return false;
        },
        (response) async {
          await _handleSuccessfulLogin(response);
          final bool restored = await syncSessionFromFirebase(
            forceRefresh: true,
          );
          if (!restored) {
            _setLoading(false);
            return false;
          }
          await loadCurrentUser();
          await LocalAuthService().login();
          _setLoading(false);
          _setError(null);
          return true;
        },
      );
    } catch (e) {
      _setLoading(false);
      _setError(_localizeAuthMessage(e.toString()));
      return false;
    }
  }

  Future<void> _handleSuccessfulLogin(LoginUserResponse response) async {
    _accessToken = response.accessToken;
    if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
      _refreshToken = response.refreshToken;
    }
    _currentUser = CurrentUserResponse(
      id: response.user.id,
      email: response.user.email,
      fullName: response.user.nombreCompleto,
      isActive: true, // Default or from user model if added
      isSuperuser: false,
      createdAt: DateTime.parse(response.user.fechaCreacion),
      updatedAt: DateTime.parse(response.user.fechaActualizacion),
      photoUrl: response.user.photoUrl,
    );

    await _updateTokenExpiration(response.accessToken);
    await _saveAuthData();
    // We already have current user data, so notify
    notifyListeners();
  }

  Future<void> logout() async {
    final String? userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    try {
      await LocalAuthService().logout();
      await authRepository.logout();
    } finally {
      await _clearAuthData();
      await AppDataCleanupService.clearUserScopedData(userId: userId);
    }
    notifyListeners();
  }

  // Expone un manejador para eventos de reanudación de la app (foreground)
  Future<void> onAppResumed() async {
    final bool ok = await syncSessionFromFirebase();
    if (ok) {
      await loadCurrentUser();
    }
  }

  Future<bool> syncSessionFromFirebase({
    bool forceRefresh = false,
    bool notify = true,
  }) async {
    final firebase_auth.User? initialUser =
        firebase_auth.FirebaseAuth.instance.currentUser;
    if (initialUser == null) {
      await _clearAuthData(notify: notify);
      return false;
    }

    try {
      await initialUser.reload();
    } catch (_) {
      // Si no hay red, seguimos con el usuario en caché del SDK.
    }

    final firebase_auth.User? user =
        firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      await _clearAuthData(notify: notify);
      return false;
    }

    if (_requiresVerifiedEmail(user) && !user.emailVerified) {
      _errorMessage =
          'Debes verificar tu correo antes de continuar. Revisa tu bandeja de entrada y la carpeta de spam/correo no deseado.';
      await LocalAuthService().logout();
      await authRepository.logout();
      await _clearAuthData(notify: false);
      await AppDataCleanupService.clearUserScopedData(userId: user.uid);
      if (notify) {
        notifyListeners();
      }
      return false;
    }

    final String? token = await user.getIdToken(forceRefresh);
    if (token == null || token.isEmpty) {
      await _clearAuthData(notify: notify);
      return false;
    }

    _accessToken = token;
    _refreshToken = user.refreshToken;
    await _updateTokenExpiration(token);
    await _saveAuthData();

    if (notify) {
      notifyListeners();
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
      await AuthSessionStorage.save(
        accessToken: _accessToken,
        refreshToken: _refreshToken,
        tokenExpiry: _tokenExpiration?.toIso8601String(),
        currentUserJson:
            _currentUser != null ? jsonEncode(_currentUser!.toJson()) : null,
      );
    } catch (e) {
      // If there's an error saving auth data, clear everything
      await _clearAuthData();
    }
  }

  Future<void> _loadAuthData() async {
    try {
      final snapshot = await AuthSessionStorage.read();
      _accessToken = snapshot.accessToken;
      _refreshToken = snapshot.refreshToken;

      final String? expiryString = snapshot.tokenExpiry;
      if (expiryString != null) {
        _tokenExpiration = DateTime.parse(expiryString);
      }

      final String? userJson = snapshot.currentUserJson;
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

  Future<void> _clearAuthData({bool notify = true}) async {
    try {
      await AuthSessionStorage.clear();

      _accessToken = null;
      _refreshToken = null;
      _tokenExpiration = null;
      _currentUser = null;

      if (notify) {
        notifyListeners();
      }
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
        (AuthFailure failure) =>
            _setError(_localizeAuthMessage(failure.message)),
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
      final bool restored = await syncSessionFromFirebase();
      if (!restored) {
        _errorMessage =
            'Tu sesión no está disponible. Inicia sesión nuevamente.';
        notifyListeners();
        return const Left(
          AuthFailure(
            message: 'Tu sesión no está disponible. Inicia sesión nuevamente.',
          ),
        );
      }

      final Either<AuthFailure, CurrentUserResponse> result =
          await authRepository.getCurrentUser();
      return result.fold(
        (AuthFailure failure) {
          _errorMessage = _localizeAuthMessage(failure.message);
          if (failure.message.toLowerCase().contains('expired') ||
              failure.message.toLowerCase().contains('invalid')) {
            _clearAuthData();
          }
          notifyListeners();
          return Left(AuthFailure(message: _errorMessage!));
        },
        (CurrentUserResponse user) {
          _currentUser = user;
          _saveAuthData();
          notifyListeners();
          return Right(user);
        },
      );
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
      await _clearAuthData();
      notifyListeners();
      return const Left(
        AuthFailure(message: 'Ocurrió un error inesperado. Intenta de nuevo.'),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Either<AuthFailure, void>> login() async {
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
          SecurityLogger().logAuthFailure(
            failure.statusCode != null
                ? 'status_code_${failure.statusCode}'
                : (failure.message.toLowerCase().contains('incorrect')
                    ? 'wrong_password_or_email'
                    : 'auth_failure'),
          );
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
            // Account not verified — se reenvió el correo automáticamente
            errorMessage =
                'Su cuenta no ha sido verificada. Hemos reenviado el correo de verificación. Por favor, revise su bandeja de entrada y la carpeta de spam/correo no deseado.';
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
                    ? _localizeAuthMessage(failure.message)
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
          await _handleSuccessfulLogin(response);
          final bool restored = await syncSessionFromFirebase(
            forceRefresh: true,
          );
          if (!restored) {
            return Left(
              AuthFailure(
                message:
                    _errorMessage ??
                    'No se pudo restaurar la sesión autenticada.',
              ),
            );
          }
          await LocalAuthService().login();
          await loadCurrentUser();
          return const Right(null);
        },
      );
    } catch (e) {
      final message = _localizeAuthMessage(e.toString());
      _setError(message);
      return Left(AuthFailure(message: message));
    } finally {
      _setLoading(false);
    }
  }

  String _localizeAuthMessage(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
    if (normalized.contains('please fill in the required fields')) {
      return 'Completa los campos requeridos.';
    }
    if (normalized.contains('an unexpected error occurred')) {
      return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
    if (normalized.contains('network') ||
        normalized.contains('socketexception') ||
        normalized.contains('failed host lookup')) {
      return 'Error de conexión. Verifica tu internet e intenta nuevamente.';
    }
    if (normalized.contains('user-not-found') ||
        normalized.contains('wrong-password') ||
        normalized.contains('invalid-credential') ||
        normalized.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (normalized.contains('invalid-email') ||
        normalized.contains('badly formatted')) {
      return 'Ingresa un correo electrónico válido.';
    }
    if (normalized.contains('too-many-requests')) {
      return 'Demasiados intentos. Espera un momento antes de volver a intentar.';
    }
    if (normalized.contains('email-already-in-use')) {
      return 'Ese correo ya está registrado.';
    }
    if (normalized.contains('weak-password')) {
      return 'La contraseña es demasiado débil.';
    }
    if (normalized.contains('verify your email') ||
        normalized.contains('email-not-verified')) {
      return 'Debes verificar tu correo antes de continuar. Revisa tu bandeja de entrada y la carpeta de spam/correo no deseado.';
    }
    if (normalized.contains('session') && normalized.contains('expired')) {
      return 'Tu sesión expiró. Inicia sesión nuevamente.';
    }
    return message;
  }

  bool _requiresVerifiedEmail(firebase_auth.User user) {
    final providerIds =
        user.providerData.map((info) => info.providerId).toSet();
    return providerIds.contains(firebase_auth.EmailAuthProvider.PROVIDER_ID);
  }
}
