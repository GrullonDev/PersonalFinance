import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:personal_finance/features/profile/domain/entities/profile_info.dart';
import 'package:personal_finance/features/profile/presentation/widgets/profile_menu_item.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/features/notifications/presentation/providers/notification_prefs_provider.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_repository.dart'
    as notif_repo;
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/features/settings/presentation/pages/notifications_detail_page.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:personal_finance/features/categories/presentation/pages/categories_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/security_detail_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/help_detail_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/about_page.dart';
import 'package:personal_finance/features/privacy/pages/privacy_policy_page.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileBloc, ProfileState>(
    builder: (BuildContext context, ProfileState state) {
      if (state.loading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (state.error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(state.error!, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        );
      }

      final String fullName = state.info?.fullName ?? 'Usuario';
      final String email = state.info?.email ?? '';
      final String? photoUrl = state.info?.photoUrl;
      final String initials = _getInitials(fullName);

      return CustomScrollView(
        slivers: <Widget>[
          // Header con gradiente verde
          _buildHeader(context, fullName, email, initials, photoUrl),

          // Contenido
          SliverToBoxAdapter(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),

                // Secciones de menú
                _buildMenuSection(
                  context,
                  title: 'CUENTA',
                  items: <Widget>[
                    ProfileMenuItem(
                      icon: Icons.person_outline,
                      title: 'Editar perfil',
                      // subtitle: 'Actualiza tu información personal',
                      onTap: () {
                        final bloc = context.read<ProfileBloc>();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => BlocProvider<ProfileBloc>.value(
                                  value: bloc,
                                  child: const EditProfilePage(),
                                ),
                          ),
                        );
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.security,
                      title: 'Seguridad',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SecurityDetailPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildMenuSection(
                  context,
                  title: 'PREFERENCIAS',
                  items: <Widget>[
                    ProfileMenuItem(
                      icon: Icons.notifications_none,
                      title: 'Notificaciones',
                      // subtitle: 'Gestiona tus alertas',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _NotificationsEntry(),
                          ),
                        );
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.category_outlined,
                      title: 'Gestionar Categorías',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CategoriesPage(),
                          ),
                        );
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.palette_outlined,
                      title: 'Apariencia',
                      // subtitle: 'Tema y personalización',
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildMenuSection(
                  context,
                  title: 'AYUDA Y SOPORTE',
                  items: <Widget>[
                    ProfileMenuItem(
                      icon: Icons.help_outline,
                      title: 'Centro de ayuda',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HelpDetailPage(),
                          ),
                        );
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.info_outline,
                      title: 'Acerca de',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Política de privacidad',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PrivacyPolicyPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Botón de cerrar sesión
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      );
    },
  );

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final List<String> parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Widget _buildHeader(
    BuildContext context,
    String fullName,
    String email,
    String initials,
    String? photoUrl,
  ) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final ProfileInfo? info = context.read<ProfileBloc>().state.info;

    // Usar firstName y lastName si están disponibles, sino usar fullName
    final String displayName =
        (info?.firstName != null && info?.lastName != null)
            ? '${info!.firstName} ${info.lastName}'
            : fullName;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: primaryColor,
      automaticallyImplyLeading: false, // Quita la flecha de retroceso
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                primaryColor,
                primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  // Avatar grande con foto o iniciales
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
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
                                          info?.firstName,
                                          info?.lastName,
                                          primaryColor,
                                        ),
                                  ),
                                )
                                : Center(
                                  child: Text(
                                    photoUrl,
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                ))
                            : _buildInitialsAvatar(
                              context,
                              info?.firstName,
                              info?.lastName,
                              primaryColor,
                            ),
                  ),
                  const SizedBox(height: 12),

                  // Nombre (firstName + lastName)
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(
    BuildContext context,
    String? firstName,
    String? lastName,
    Color primaryColor,
  ) {
    String initials = '?';

    if (firstName != null && firstName.isNotEmpty) {
      initials = firstName[0].toUpperCase();
      if (lastName != null && lastName.isNotEmpty) {
        initials += lastName[0].toUpperCase();
      }
    } else if (lastName != null && lastName.isNotEmpty) {
      initials = lastName[0].toUpperCase();
    }

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    ),
  );

  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext ctx) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
    );

    if (confirm == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RoutePath.login, (_) => false);
      }
    }
  }
}

// Entry para notificaciones con provider inyectado desde Profile
class _NotificationsEntry extends StatelessWidget {
  const _NotificationsEntry();

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<NotificationPrefsProvider>(
        create:
            (_) => NotificationPrefsProvider(
              getIt<notif_repo.NotificationRepository>(),
            )..load(),
        child: const NotificationsDetailPage(),
      );
}
