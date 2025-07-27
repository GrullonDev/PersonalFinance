import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:personal_finance/features/auth/logic/auth_provider.dart';
import 'package:personal_finance/features/profile/domain/profile_repository.dart';
import 'package:personal_finance/features/profile/logic/profile_provider.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final ProfileProvider provider = context.read<ProfileProvider>();
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      await provider.uploadPhoto(File(file.path));
    }
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<ProfileProvider>(
        create: (_) {
          final ProfileProvider provider = ProfileProvider(
            repository: getIt<ProfileRepository>(),
          );
          provider.loadProfile();
          return provider;
        },
        builder: (BuildContext context, _) =>
            Consumer2<AuthProvider, ProfileProvider>(
          builder: (
            BuildContext context,
            AuthProvider auth,
            ProfileProvider profile,
            _,
          ) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                GestureDetector(
                  onTap: () => _pickImage(context),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: profile.profile?.photoUrl != null
                        ? NetworkImage(profile.profile!.photoUrl!)
                        : null,
                    child: profile.profile?.photoUrl == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.profile != null
                      ? '${profile.profile!.firstName} ${profile.profile!.lastName}'
                      : 'Usuario Invitado',
                ),
                if (profile.profile != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(profile.profile!.email),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          await auth.logout();
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
        ),
      );
}
