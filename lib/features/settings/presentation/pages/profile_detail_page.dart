import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:personal_finance/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:personal_finance/features/profile/domain/repositories/profile_backend_repository.dart';
import 'package:personal_finance/utils/injection_container.dart';

class ProfileDetailPage extends StatelessWidget {
  const ProfileDetailPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ProfileBloc>(
    create:
        (_) =>
            ProfileBloc(getIt<ProfileBackendRepository>())
              ..add(ProfileLoadMe()),
    child: const ProfileDetailView(),
  );
}

class ProfileDetailView extends StatelessWidget {
  const ProfileDetailView({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileBloc, ProfileState>(
    builder: (BuildContext context, ProfileState state) {
      if (state.loading) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Perfil'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      final authUser = context.watch<AuthProvider>().currentUser;
      final String fullName =
          (state.info?.fullName != null && state.info!.fullName.isNotEmpty)
              ? state.info!.fullName
              : (authUser?.fullName != null && authUser!.fullName.isNotEmpty
                  ? authUser.fullName
                  : 'Usuario');
      final String email =
          (state.info?.email != null && state.info!.email.isNotEmpty)
              ? state.info!.email
              : (authUser?.email ?? '');
      final String phoneNumber =
          (state.info?.phoneNumber != null &&
                  state.info!.phoneNumber!.isNotEmpty)
              ? state.info!.phoneNumber!
              : (authUser?.phoneNumber != null &&
                      authUser!.phoneNumber!.isNotEmpty
                  ? authUser.phoneNumber!
                  : 'No especificado');
      final String? photoUrl =
          (state.info?.photoUrl != null && state.info!.photoUrl!.isNotEmpty)
              ? state.info!.photoUrl
              : authUser?.photoUrl;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Profile picture / initials avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child:
                        photoUrl != null && photoUrl.isNotEmpty
                            ? (photoUrl.contains('://')
                                ? ClipOval(
                                  child: Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => _buildInitialsAvatar(
                                          context,
                                          fullName,
                                        ),
                                  ),
                                )
                                : Center(
                                  child: Text(
                                    photoUrl,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                ))
                            : _buildInitialsAvatar(context, fullName),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Profile fields card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildProfileField(
                            context,
                            label: 'Nombre Completo',
                            value: fullName,
                            icon: Icons.person_outline,
                          ),
                          const Divider(height: 24),
                          _buildProfileField(
                            context,
                            label: 'Correo electrónico',
                            value: email,
                            icon: Icons.email_outlined,
                          ),
                          const Divider(height: 24),
                          _buildProfileField(
                            context,
                            label: 'Teléfono',
                            value: phoneNumber,
                            icon: Icons.phone_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar Perfil'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final bloc = context.read<ProfileBloc>();
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder:
                                (BuildContext context) =>
                                    BlocProvider<ProfileBloc>.value(
                                      value: bloc,
                                      child: const EditProfilePage(),
                                    ),
                          ),
                        ).then((_) {
                          bloc.add(ProfileLoadMe());
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _buildInitialsAvatar(BuildContext context, String name) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final initials = _getInitials(name);
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final List<String> parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Widget _buildProfileField(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    ),
  );
}
