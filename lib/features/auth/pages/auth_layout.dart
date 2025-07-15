import 'package:flutter/material.dart';

import 'package:personal_finance/features/auth/widgets/social_buttons.dart';
import 'package:personal_finance/utils/app_localization.dart';

class LoginLayout extends StatelessWidget {
  const LoginLayout({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            AppLocalizations.of(context)!.signInToContinue,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          const SocialLoginButtons(),
        ],
      ),
    ),
  );
}
