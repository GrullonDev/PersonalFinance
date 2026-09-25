import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/core/services/haptic_feedback_service.dart';
import 'package:personal_finance/features/settings/presentation/providers/settings_provider.dart';
import 'package:personal_finance/features/settings/presentation/pages/help_detail_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/notifications_detail_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/profile_detail_page.dart';
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
        _buildSectionTitle(context, 'CUENTA'),
        _buildSettingItem(
          context,
          icon: Icons.person,
          iconColor: Theme.of(context).colorScheme.primary,
          title: 'Perfil',
          subtitle: 'Administra tu información personal',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const ProfileDetailPage(),
              ),
            );
          },
        ),
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
        _buildSectionTitle(context, 'PREFERENCIAS'),
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
        _buildProSection(context),
        _buildSectionTitle(context, 'AYUDA Y LEGAL'),
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
      ],
    ),
  );

  Widget _buildProSection(BuildContext context) =>
      BlocBuilder<SubscriptionBloc, SubscriptionState>(
        bloc: getIt<SubscriptionBloc>(),
        builder: (context, state) {
          final isPro = state.isPremium;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
              _buildProItem(
                context,
                isPro: isPro,
                icon: Icons.auto_awesome,
                iconColor: const Color(0xFF6366F1),
                title: 'Reportes con IA',
                subtitle: 'Análisis mensual inteligente de tus finanzas',
                onProTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AiReportsPage(),
                  ),
                ),
              ),
              _buildProItem(
                context,
                isPro: isPro,
                icon: Icons.download_outlined,
                iconColor: Colors.indigo,
                title: 'Exportar datos',
                subtitle: 'Descarga tus transacciones en CSV o TXT',
                onProTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ExportDataPage(),
                  ),
                ),
              ),
              _buildProItem(
                context,
                isPro: isPro,
                icon: Icons.notifications_active_outlined,
                iconColor: Colors.orange,
                title: 'Alertas predictivas',
                subtitle: 'Recibe alertas antes de sobrepasar tu presupuesto',
                onProTap: () => _showComingSoon(context, 'Alertas Predictivas'),
              ),
              _buildProItem(
                context,
                isPro: isPro,
                icon: Icons.repeat,
                iconColor: Colors.teal,
                title: 'Transacciones recurrentes',
                subtitle: 'Automatiza salarios, alquiler y suscripciones',
                onProTap: () =>
                    _showComingSoon(context, 'Transacciones Recurrentes'),
              ),
              _buildSettingItem(
                context,
                icon: Icons.palette_outlined,
                iconColor: Colors.pink,
                title: 'Temas',
                subtitle: 'Personaliza colores y modo de la app',
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ThemesPage(),
                  ),
                ),
              ),
            ],
          );
        },
      );

  Widget _buildUpgradeBanner(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

  Widget _buildProItem(
    BuildContext context, {
    required bool isPro,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onProTap,
  }) {
    final locked = !isPro;
    return Opacity(
      opacity: locked ? 0.6 : 1.0,
      child: InkWell(
        onTap: locked ? () => PaywallPage.show(context) : onProTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  if (locked)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              Icon(
                locked ? Icons.lock_outline : Icons.arrow_forward_ios,
                size: locked ? 18 : 16,
                color: locked ? Colors.grey[500] : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
