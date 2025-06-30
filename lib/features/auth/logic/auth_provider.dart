import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/features/auth/domain/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.authRepository});

  final AuthRepository authRepository;

  Future<void> signInWithGoogle(BuildContext context) async {
    await authRepository.signInWithGoogle();
    await _persistLogin();
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<void> signInWithFacebook(BuildContext context) async {
    await authRepository.signInWithFacebook();
    await _persistLogin();
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<void> signInWithApple(BuildContext context) async {
    await authRepository.signInWithApple();
    await _persistLogin();
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<void> _persistLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }
}
