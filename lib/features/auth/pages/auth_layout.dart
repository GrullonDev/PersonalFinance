import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:personal_finance/features/auth/logic/auth_provider.dart';
import 'package:personal_finance/features/auth/widgets/social_buttons.dart';

class LoginLayout extends StatelessWidget {
  const LoginLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder:
          (BuildContext context, AuthProvider model, __) => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 40),
                  SocialLoginButtons(),
                ],
              ),
            ),
          ),
    );
  }
}
