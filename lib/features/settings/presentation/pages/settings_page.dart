import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personal_finance/core/services/haptic_feedback_service.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/features/settings/presentation/providers/settings_provider.dart';
import 'package:personal_finance/features/settings/presentation/pages/help_detail_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/notifications_detail_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/security_detail_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/ai_reports_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/export_data_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/themes_page.dart';
import 'package:personal_finance/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:personal_finance/features/subscription/presentation/pages/paywall_page.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_repository.dart'
    as notif_repo;
import 'package:personal_finance/features/settings/presentation/pages/about_page.dart';
import 'package:personal_finance/features/privacy/pages/privacy_policy_page.dart';
import 'package:personal_finance/features/notifications/presentation/providers/notification_prefs_provider.dart';
import 'package:personal_finance/features/goals/presentation/pages/goals_crud_page.dart';
import 'package:personal_finance/features/debts/presentation/pages/debts_page.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Configuración'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: ListView(
      children: <Widget>[
        _buildProfileHeader(context),
        _buildProSection(context),
        _buildSectionTitle(context, 'GENERAL'),
        _buildSettingItem(
          context,
          icon: Icons.security,
          iconColor: Colors.green,
          title: 'Seguridad',
          subtitle: 'Cambia tu contraseña',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const SecurityDetailPage(),
              ),
            );
          },
        ),
        _buildHideAmountsOption(context),
        _buildSettingItem(
          context,
          icon: Icons.notifications,
          iconColor: Colors.orange,
          title: 'Notificaciones',
          subtitle: 'Activa o desactiva las notificaciones',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder:
                    (BuildContext context) =>
                        ChangeNotifierProvider<NotificationPrefsProvider>(
                          create:
                              (_) => NotificationPrefsProvider(
                                getIt<notif_repo.NotificationRepository>(),
                              )..load(),
                          child: const NotificationsDetailPage(),
                        ),
              ),
            );
          },
        ),
        _buildSectionTitle(context, 'FINANZAS'),
        _buildSettingItem(
          context,
          icon: Icons.track_changes,
          iconColor: Colors.teal,
          title: 'Metas de Ahorro',
          subtitle: 'Configura y administra tus metas de ahorro',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const GoalsCrudPage(),
              ),
            );
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.money_off,
          iconColor: Colors.red,
          title: 'Control de Deudas',
          subtitle: 'Registra y gestiona tus deudas y pagos',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const DebtsPage(),
              ),
            );
          },
        ),
        _buildSectionTitle(context, 'PERSONALIZACIÓN'),
        _buildSettingItem(
          context,
          icon: Icons.palette_outlined,
          iconColor: Colors.pink,
          title: 'Temas',
          subtitle: 'Personaliza colores y modo de la app',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const ThemesPage()),
          ),
        ),
        _buildSectionTitle(context, 'SOPORTE E INFORMACIÓN'),
        _buildSettingItem(
          context,
          icon: Icons.help_outline,
          iconColor: Colors.purple,
          title: 'Centro de Ayuda',
          subtitle: 'Preguntas frecuentes y soporte',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const HelpDetailPage(),
              ),
            );
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.privacy_tip_outlined,
          iconColor: Colors.blueGrey,
          title: 'Privacidad',
          subtitle: 'Tu protección es nuestra prioridad',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const PrivacyPolicyPage(),
              ),
            );
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.info_outline,
          iconColor: Colors.teal,
          title: 'Acerca de',
          subtitle: 'Versión e información legal',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const AboutPage(),
              ),
            );
          },
        ),
        _buildLogoutButton(context),
        _buildVersionInfo(),
      ],
    ),
  );

  // ── Profile header ────────────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final name = user?.fullName ?? 'Usuario';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundImage:
                photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            child:
                (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                      initials.isNotEmpty ? initials : 'U',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ── PRO section ───────────────────────────────────────────────────────────

  Widget _buildProSection(BuildContext context) =>
      BlocBuilder<SubscriptionBloc, SubscriptionState>(
        bloc: getIt<SubscriptionBloc>(),
        builder: (context, state) {
          final isPro = state.isPremium;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    Text(
                      'HERRAMIENTAS PRO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isPro ? 'ACTIVO' : 'PRO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPro) _buildUpgradeBanner(context),
              _buildProGrid(context, isPro: isPro),
              const SizedBox(height: 8),
            ],
          );
        },
      );

  Widget _buildProGrid(BuildContext context, {required bool isPro}) {
    final tools = [
      _ProToolData(
        icon: Icons.auto_awesome,
        color: const Color(0xFF6366F1),
        label: 'AI Reports',
        onProTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const AiReportsPage()),
        ),
      ),
      _ProToolData(
        icon: Icons.download_outlined,
        color: Colors.indigo,
        label: 'Export data',
        onProTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const ExportDataPage()),
        ),
      ),
      _ProToolData(
        icon: Icons.notifications_active_outlined,
        color: Colors.orange,
        label: 'Predictive alerts',
        onProTap: () => _showComingSoon(context, 'Alertas Predictivas'),
      ),
      _ProToolData(
        icon: Icons.repeat,
        color: Colors.teal,
        label: 'Recurring trans.',
        onProTap: () =>
            _showComingSoon(context, 'Transacciones Recurrentes'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E1B4B),
              const Color(0xFF312E81).withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3,
          children: tools
              .map(
                (tool) => _buildProGridCell(
                  context,
                  tool: tool,
                  isPro: isPro,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildProGridCell(
    BuildContext context, {
    required _ProToolData tool,
    required bool isPro,
  }) => InkWell(
    onTap: isPro ? tool.onProTap : () => PaywallPage.show(context),
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(tool.icon, color: tool.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tool.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (!isPro)
            const Icon(Icons.lock, color: Colors.white38, size: 11),
        ],
      ),
    ),
  );

  Widget _buildUpgradeBanner(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: InkWell(
      onTap: () => PaywallPage.show(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Desbloquea todas las herramientas PRO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ver planes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ── Logout ────────────────────────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: InkWell(
      onTap: () => _confirmLogout(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<AuthProvider>().logout();
      } catch (_) {}
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RoutePath.login, (_) => false);
      }
    }
  }

  // ── Version ───────────────────────────────────────────────────────────────

  Widget _buildVersionInfo() => FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snapshot) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: Center(
        child: Text(
          snapshot.hasData
              ? 'Versión ${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})'
              : '',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ),
    ),
  );

  // ── Shared helpers ────────────────────────────────────────────────────────

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.construction, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$feature disponible muy pronto'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
      ),
    ),
  );

  Widget _buildHideAmountsOption(BuildContext context) =>
      Consumer<SettingsProvider>(
        builder:
            (BuildContext context, SettingsProvider settings, Widget? child) =>
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.visibility_off_outlined,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Ocultar montos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Esconde saldos y cantidades en la app',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.hideAmounts,
                        onChanged: (_) async {
                          await HapticFeedbackService.selection();
                          await settings.toggleHideAmounts();
                        },
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
      );

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    ),
  );
}

class _ProToolData {
  const _ProToolData({
    required this.icon,
    required this.color,
    required this.label,
    required this.onProTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onProTap;
}
