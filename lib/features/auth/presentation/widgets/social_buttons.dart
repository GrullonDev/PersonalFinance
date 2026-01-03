import 'package:flutter/material.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AuthProvider>(
    builder: (BuildContext context, AuthProvider provider, _) {
      if (provider.isLoading) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
            strokeWidth: 4,
          ),
        );
      }
      if (provider.errorMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
          provider.clearError();
        });
      }
      return const Column();
    },
  );
}
