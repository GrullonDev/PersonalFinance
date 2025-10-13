import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/settings_model.dart';

import 'help_detail_page.dart';
import 'notifications_detail_page.dart';
import 'profile_detail_page.dart';
import 'security_detail_page.dart';

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
        _buildSectionTitle(context, 'APARIENCIA'),
        _buildDarkModeOption(context),
        _buildSectionTitle(context, 'CUENTA'),
        _buildSettingItem(
          context,
          icon: Icons.person,
          iconColor: Colors.blue,
          title: 'Perfil',
          subtitle: 'Administra tu información personal',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const SecurityDetailPage(),
              ),
            );
          },
        ),
        _buildSectionTitle(context, 'PREFERENCIAS'),
        _buildSettingItem(
          context,
          icon: Icons.notifications,
          iconColor: Colors.orange,
          title: 'Notificaciones',
          subtitle: 'Activa o desactiva las notificaciones',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (BuildContext context) => const NotificationsDetailPage(),
              ),
            );
          },
        ),
        _buildSectionTitle(context, 'AYUDA'),
        _buildSettingItem(
          context,
          icon: Icons.help,
          iconColor: Colors.purple,
          title: 'Ayuda/Soporte',
          subtitle: 'Obtén respuestas a tus preguntas',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const HelpDetailPage(),
              ),
            );
          },
        ),
      ],
    ),
  );

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

  Widget _buildDarkModeOption(BuildContext context) => Consumer<SettingsModel>(
    builder:
        (BuildContext context, SettingsModel settings, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.dark_mode, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Modo Oscuro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Activa o desactiva el modo oscuro',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.darkMode,
                onChanged: (_) async {
                  await settings.toggleDarkMode();
                },
                activeThumbColor: Colors.blue,
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
              color: iconColor.withOpacity(0.1),
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
