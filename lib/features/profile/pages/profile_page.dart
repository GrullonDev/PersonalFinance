import 'package:flutter/material.dart';
import 'package:personal_finance/features/auth/logic/auth_provider.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AuthProvider>(
    builder:
        (BuildContext context, AuthProvider provider, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 12),
              const Text('Usuario Invitado'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed:
                    provider.isLoading
                        ? null
                        : () async {
                          await provider.logout();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              RoutePath.login,
                            );
                          }
                        },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
  );
}
