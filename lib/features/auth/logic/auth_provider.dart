import 'dart:io';

import 'package:flutter/material.dart';

import 'package:personal_finance/features/auth/data/local_auth_service.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.authRepository});

  final AuthRepository authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

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
      if (!Platform.isIOS) {
        throw Exception('Sign in with Apple no soportado en esta plataforma');
      }
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
    _setLoading(true);
    try {
      await authRepository.logout();
      await LocalAuthService().logout();
    } catch (e) {
      _setError(e.toString());
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
}
