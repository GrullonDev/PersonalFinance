import 'dart:io';

import 'package:flutter/material.dart';

import 'package:personal_finance/features/auth/domain/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.authRepository});

  final AuthRepository authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      if (!Platform.isAndroid) {
        throw Exception('Google Sign-In no soportado en esta plataforma');
      }
      await authRepository.signInWithGoogle();
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
      _setLoading(false);
      _setError(null);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
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
