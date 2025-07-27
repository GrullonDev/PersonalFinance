import 'dart:io';

import 'package:flutter/material.dart';
import 'package:personal_finance/features/auth/logic/auth_provider.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:provider/provider.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AuthProvider>(
      builder: (BuildContext context, AuthProvider provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
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
        return Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login, size: 24),
                label: Text(AppLocalizations.of(context)!.continueWithGoogle),
                onPressed:
                    provider.isLoading
                        ? null
                        : () async {
                          final bool success =
                              await provider.signInWithGoogle();
                          if (success && context.mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/dashboard',
                            );
                          }
                        },
              ),
            ),
            if (Platform.isIOS) ...<Widget>[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.apple, size: 24),
                  label: Text(AppLocalizations.of(context)!.continueWithApple),
                  onPressed:
                      provider.isLoading
                          ? null
                          : () async {
                            final bool success =
                                await provider.signInWithApple();
                            if (success && context.mounted) {
                              Navigator.pushReplacementNamed(
                                context,
                                '/dashboard',
                              );
                            }
                          },
                ),
              ),
            ],
          ],
        );
      },
    );
}
