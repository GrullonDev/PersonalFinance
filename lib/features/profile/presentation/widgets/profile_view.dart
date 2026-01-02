import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:personal_finance/features/profile/domain/entities/profile_info.dart';
import 'package:personal_finance/features/profile/presentation/widgets/profile_menu_item.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/features/notifications/presentation/providers/notification_prefs_provider.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_repository.dart'
    as notif_repo;
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/features/settings/presentation/pages/notifications_detail_page.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:personal_finance/features/categories/presentation/pages/categories_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
                      // subtitle: 'Contraseña y autenticación',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _PrivacySecurityPage(),
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
                      // subtitle: 'Preguntas frecuentes',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _HelpCenterPage(),
                          ),
                        );
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.info_outline,
                      title: 'Acerca de',
                      // subtitle: 'Versión e información',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _AboutPage(),
                          ),
                        );
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Política de privacidad',
                      // subtitle: 'Términos y condiciones',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _PrivacySecurityPage(),
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
              colors: <Color>[primaryColor, primaryColor.withOpacity(0.8)],
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
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child:
                        photoUrl != null && photoUrl.isNotEmpty
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
                      color: Colors.white.withOpacity(0.9),
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

  Widget _buildStatsCard(BuildContext context) =>
  // TODO: Obtener datos reales del dashboard o provider
  Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.analytics_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Resumen Financiero',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          children: <Widget>[
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.account_balance_wallet,
                label: 'Balance',
                value: '\$0.00',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.trending_up,
                label: 'Ingresos',
                value: '\$0.00',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: <Widget>[
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.trending_down,
                label: 'Gastos',
                value: '\$0.00',
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.flag,
                label: 'Metas',
                value: '0',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _buildQuickActions(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Accesos Rápidos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Row(
          children: <Widget>[
            Expanded(
              child: _QuickActionCard(
                icon: Icons.dashboard,
                label: 'Dashboard',
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, '/'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.receipt_long,
                label: 'Presupuestos',
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(context, '/budgets'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: <Widget>[
            Expanded(
              child: _QuickActionCard(
                icon: Icons.flag,
                label: 'Metas',
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/goals'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.swap_horiz,
                label: 'Transacciones',
                color: Colors.teal,
                onTap: () => Navigator.pushNamed(context, '/transactions'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

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
                color: Colors.black.withOpacity(0.05),
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
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (_) => false);
      }
    }
  }
}

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Text(
          'Preguntas frecuentes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          '¿Cómo agrego una transacción?',
          'Usa el botón + en la pantalla principal para agregar ingresos o gastos.',
        ),
        _buildFAQItem(
          '¿Cómo creo una meta de ahorro?',
          'Ve a la sección de Metas y toca el botón "Nueva meta".',
        ),
        _buildFAQItem(
          '¿Cómo gestiono categorías?',
          'Puedes agregar categorías personalizadas desde el perfil.',
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

  Widget _buildFAQItem(String question, String answer) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          question,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(answer, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 50,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              'Personal Finance',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          Center(
            child: Text(
              'Versión ${_version ?? '...'}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'App para registrar ingresos y gastos, gestionar categorías, '
            'presupuestos y metas, con sincronización a un backend y notificaciones.',
            style: TextStyle(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          const Divider(),

          const SizedBox(height: 16),

          _buildInfoRow(Icons.code, 'Desarrollado con Flutter'),
          _buildInfoRow(Icons.security, 'Tus datos están seguros'),
          _buildInfoRow(Icons.update, 'Actualizaciones regulares'),
        ],
      ),
    ),
  );

  Widget _buildInfoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );
}
