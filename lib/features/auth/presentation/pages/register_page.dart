import 'package:flutter/material.dart';
import 'package:personal_finance/features/auth/presentation/pages/register_layout.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/features/auth/presentation/providers/register_provider.dart';
import 'package:personal_finance/features/profile/domain/profile_repository.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.read<AuthProvider>();
    final ProfileRepository profileRepository = getIt<ProfileRepository>();

    return ChangeNotifierProvider<RegisterProvider>(
      create: (_) => RegisterProvider(
        authProvider: authProvider,
        profileRepository: profileRepository,
      ),
      child: const RegisterLayout(),
    );
  }
}
