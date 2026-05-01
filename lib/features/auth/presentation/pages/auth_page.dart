import 'package:flutter/material.dart';

import 'package:personal_finance/core/presentation/widgets/premium_background.dart';
import 'package:personal_finance/features/auth/presentation/pages/auth_layout.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => const PremiumBackground(
    child: Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: AuthLayout(),
      ),
    ),
  );
}
