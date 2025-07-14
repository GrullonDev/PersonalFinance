import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/logic/auth_provider.dart';
import 'package:personal_finance/features/auth/pages/auth_layout.dart';
import 'package:personal_finance/utils/injection_container.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(
        authRepository: getIt<AuthRepository>(),
      ),
      builder: (BuildContext context, _) => const Scaffold(
        body: Padding(padding: EdgeInsets.all(24), child: LoginLayout()),
      ),
    );
  }
}
