import 'package:flutter/material.dart';
import 'package:personal_finance/features/settings/presentation/pages/appearance_settings_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/help_detail_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/notifications_detail_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/profile_detail_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/security_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_repository.dart'
    as notif_repo;
import 'package:personal_finance/features/settings/presentation/pages/about_page.dart';
import 'package:personal_finance/features/privacy/pages/privacy_policy_page.dart';
import 'package:personal_finance/features/notifications/presentation/providers/notification_prefs_provider.dart';
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
        _buildSectionTitle(context, 'CUENTA'),
        _buildSettingItem(
          context,
          icon: Icons.person_outline_rounded,
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
          icon: Icons.security_rounded,
          iconColor: Colors.green,
          title: 'Seguridad',
          subtitle: 'Contraseñas y métodos de acceso',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const SecurityDetailPage(),
              ),
            );
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.cloud_sync_rounded,
          iconColor: Colors.blue,
          title: 'Sincronización',
          subtitle: 'Respaldo en la nube y dispositivos',
          onTap: () {
            // TODO: Implement Sincronización
          },
        ),
        _buildSectionTitle(context, 'PREFERENCIAS'),
        _buildSettingItem(
          context,
          icon: Icons.category_rounded,
          iconColor: Colors.amber,
          title: 'Categorías',
          subtitle: 'Administra tus categorías de ingreso y gasto',
          onTap: () {
            Navigator.pushNamed(context, '/categories');
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.color_lens_outlined,
          iconColor: Colors.purple,
          title: 'Apariencia',
          subtitle: 'Tema, colores y comportamiento visual',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder:
                    (BuildContext context) => const AppearanceSettingsPage(),
              ),
            );
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.notifications_none_rounded,
          iconColor: Colors.orange,
          title: 'Notificaciones',
          subtitle: 'Mira tus avisos y alertas recibidos',
          onTap: () {
            Navigator.pushNamed(context, RoutePath.notificationsInbox);
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.alarm_rounded,
          iconColor: Colors.redAccent,
          title: 'Recordatorios',
          subtitle: 'Facturas, ahorros y presupuestos',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const NotificationsDetailPage(),
              ),
            );
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.summarize_outlined,
          iconColor: Colors.teal,
          title: 'Frecuencia de resumen',
          subtitle: 'Semanal',
          onTap: () {},
        ),
        _buildSectionTitle(context, 'AYUDA Y LEGAL'),
        _buildSettingItem(
          context,
          icon: Icons.help_outline_rounded,
          iconColor: Colors.indigo,
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
          title: 'Política de Privacidad',
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
          icon: Icons.description_outlined,
          iconColor: Colors.brown,
          title: 'Términos y Licencias',
          subtitle: 'Acuerdos legales',
          onTap: () {},
        ),
        _buildSettingItem(
          context,
          icon: Icons.info_outline_rounded,
          iconColor: Colors.cyan,
          title: 'Acerca de',
          subtitle: 'Versión de la aplicación y equipo',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const AboutPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 48),
      ],
    ),
  );

  Widget _buildSectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
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
    splashColor: iconColor.withValues(alpha: 0.1),
    highlightColor: iconColor.withValues(alpha: 0.05),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    ),
  );
}
