import 'package:flutter/material.dart';
import 'package:personal_finance/features/profile/logic/profile_logic.dart';
import 'package:personal_finance/features/profile/models/user_profile.dart';
import 'package:personal_finance/features/profile/widgets/profile_menu_item.dart';
import 'package:personal_finance/features/profile/widgets/recent_activity_list.dart';
import 'package:provider/provider.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) => Consumer<ProfileLogic>(
    builder: (BuildContext context, ProfileLogic logic, _) {
      if (logic.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final UserProfile? profile = logic.profile;
      if (profile == null) {
        return const Center(child: Text('No hay perfil disponible'));
      }

      return CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  // Profile Header
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            profile.photoUrl != null
                                ? NetworkImage(profile.photoUrl!)
                                : null,
                        child:
                            profile.photoUrl == null
                                ? Text(
                                  profile.name[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 24),
                                )
                                : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              profile.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              profile.email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _QuickActionButton(
                        icon: Icons.dashboard,
                        label: 'Dashboard',
                        onTap: () {
                          // TODO: Implementar navegación al dashboard
                        },
                      ),
                      _QuickActionButton(
                        icon: Icons.library_books,
                        label: 'Presupuestos',
                        onTap: () {
                          // TODO: Implementar navegación a presupuestos
                        },
                      ),
                      _QuickActionButton(
                        icon: Icons.flag,
                        label: 'Metas',
                        onTap: () {
                          // TODO: Implementar navegación a metas
                        },
                      ),
                      _QuickActionButton(
                        icon: Icons.person,
                        label: 'Cuenta',
                        onTap: () {
                          // TODO: Implementar navegación a cuenta
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Menu Items
                  ProfileMenuItem(
                    icon: Icons.person_outline,
                    title: 'Editar perfil',
                    onTap: () {
                      // TODO: Implementar edición de perfil
                    },
                  ),
                  ProfileMenuItem(
                    icon: Icons.notifications_none,
                    title: 'Notificaciones',
                    onTap: () {
                      // TODO: Implementar configuración de notificaciones
                    },
                  ),
                  ProfileMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Privacidad y seguridad',
                    onTap: () {
                      // TODO: Implementar configuración de privacidad
                    },
                  ),
                  ProfileMenuItem(
                    icon: Icons.help_outline,
                    title: 'Centro de ayuda',
                    onTap: () {
                      // TODO: Implementar centro de ayuda
                    },
                  ),
                  ProfileMenuItem(
                    icon: Icons.people_outline,
                    title: 'Contáctanos',
                    onTap: () {
                      // TODO: Implementar contacto
                    },
                  ),
                  ProfileMenuItem(
                    icon: Icons.logout,
                    title: 'Cerrar Sesión',
                    onTap: () async {
                      await logic.signOut();
                      // TODO: Implementar navegación al login
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ACTIVIDAD RECIENTE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: RecentActivityList(activities: logic.recentActivity),
          ),
        ],
      );
    },
  );
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}
