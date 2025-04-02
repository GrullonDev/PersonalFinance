import 'dart:io';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:personal_finance/features/auth/logic/auth_provider.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider provider = context.read<AuthProvider>();

    return Column(
      children: <Widget>[
        ElevatedButton.icon(
          icon: const Icon(Icons.g_mobiledata),
          label: const Text('Continuar con Google'),
          onPressed: () => provider.signInWithGoogle(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.facebook),
          label: const Text('Continuar con Facebook'),
          onPressed: () => provider.signInWithFacebook(context),
        ),
        if (Platform.isIOS) ...<Widget>[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.apple),
            label: const Text('Continuar con Apple'),
            onPressed: () => provider.signInWithApple(context),
          ),
        ],
      ],
    );
  }
}
