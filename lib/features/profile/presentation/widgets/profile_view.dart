import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:personal_finance/features/profile/presentation/widgets/profile_menu_item.dart';
// import 'package:personal_finance/features/profile/presentation/widgets/recent_activity_list.dart';
import 'package:personal_finance/features/profile/presentation/widgets/quick_add_category.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/features/notifications/presentation/providers/notification_prefs_provider.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_repository.dart'
    as notif_repo;
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/features/settings/presentation/pages/notifications_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileBloc, ProfileState>(
    builder: (BuildContext context, ProfileState state) {
      final Widget child;
      if (state.loading) {
        child = const Center(child: CircularProgressIndicator());
      } else if (state.error != null) {
        child = Center(child: Text(state.error!));
      } else {
        final String fullName = state.info?.fullName ?? '';
        final String email = state.info?.email ?? '';
        child = CustomScrollView(
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
                          child: Text(
                            (fullName.isNotEmpty ? fullName[0] : '?')
                                .toUpperCase(),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                fullName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                email,
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
                      icon: Icons.notifications_none,
                      title: 'Notificaciones',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (BuildContext _) => const _NotificationsEntry(),
                          ),
                        );
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Privacidad y seguridad',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (BuildContext _) =>
                                    const _PrivacySecurityPage(),
                          ),
                        );
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.help_outline,
                      title: 'Centro de ayuda',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (BuildContext _) => const _HelpCenterPage(),
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
                            builder: (BuildContext _) => const _AboutPage(),
                          ),
                        );
                      },
                    ),
                    // Add logout or other actions via AuthProvider/BLoC if needed
                  ],
                ),
              ),
            ),
            // Quick add category section
            const SliverToBoxAdapter(child: QuickAddCategory()),
            // Recent activity section can be wired later when backend supports it
          ],
        );
      }
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: child,
      );
    },
  );
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

class _PrivacySecurityPage extends StatelessWidget {
  const _PrivacySecurityPage();

  Future<String> _loadPolicy(BuildContext context) async {
    try {
      final String data = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/privacy_policy.md');
      return data;
    } catch (_) {
      return 'Política de privacidad no disponible.';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Privacidad y seguridad'),
      backgroundColor: Colors.greenAccent,
    ),
    body: FutureBuilder<String>(
      future: _loadPolicy(context),
      builder: (BuildContext context, AsyncSnapshot<String> snap) {
        final String text = snap.data ?? 'Cargando...';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(text),
        );
      },
    ),
  );
}

class _HelpCenterPage extends StatelessWidget {
  const _HelpCenterPage();

  static const String supportEmail = 'support@personalfinance.app';

  Future<void> _contact(BuildContext context) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Ayuda Personal Finance',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(const ClipboardData(text: supportEmail));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo copiado al portapapeles')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Centro de ayuda'),
      backgroundColor: Colors.greenAccent,
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Text(
          'Preguntas frecuentes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text('• ¿Cómo agrego una transacción? Usa el botón + en Inicio.'),
        const Text(
          '• ¿Cómo gestiono categorías? Ve a Perfil > Agregar categoría rápida.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _contact(context),
          icon: const Icon(Icons.email),
          label: const Text('Escríbenos'),
        ),
      ],
    ),
  );
}

class _AboutPage extends StatefulWidget {
  const _AboutPage();

  @override
  State<_AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<_AboutPage> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (_) {
      if (mounted) setState(() => _version = '1.0.1');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Acerca de'),
      backgroundColor: Colors.greenAccent,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Personal Finance',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('Versión: ${_version ?? '...'}'),
          const SizedBox(height: 16),
          const Text(
            'App para registrar ingresos y gastos, gestionar categorías, '
            'presupuestos y metas, con sincronización a un backend y notificaciones.',
          ),
        ],
      ),
    ),
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
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
