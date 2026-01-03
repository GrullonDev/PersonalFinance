import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:personal_finance/core/presentation/widgets/premium_background.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/presentation/pages/auth_layout.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/utils/injection_container.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => AuthProvider(authRepository: getIt<AuthRepository>()),
    child: const PremiumBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: AuthLayout(),
        ),
      ),
    ),
  );
}
