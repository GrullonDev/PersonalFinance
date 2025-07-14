import 'package:flutter/material.dart';

import 'package:personal_finance/features/auth/widgets/social_buttons.dart';

class LoginLayout extends StatelessWidget {
  const LoginLayout({super.key});

  @override
  Widget build(BuildContext context) => const Center(
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
  );
}
