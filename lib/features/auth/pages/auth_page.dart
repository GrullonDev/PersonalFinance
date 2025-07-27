import 'package:flutter/material.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/logic/auth_provider.dart';
import 'package:personal_finance/features/auth/pages/auth_layout.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<AuthProvider>(
    create: (_) => AuthProvider(authRepository: getIt<AuthRepository>()),
    builder:
        (BuildContext context, _) => Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: LoginLayout(),
          ),
        ),
  );
}
