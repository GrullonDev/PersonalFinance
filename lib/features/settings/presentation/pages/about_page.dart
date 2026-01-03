import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de la App'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 48),
            _buildAppIdentity(colorScheme, theme),
            const SizedBox(height: 48),
            _buildInfoList(colorScheme, theme, context),
            const SizedBox(height: 48),
            _buildBrandFooter(colorScheme, theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIdentity(ColorScheme colorScheme, ThemeData theme) => Column(
    children: [
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Icon(
                  Icons.account_balance_wallet,
                  size: 50,
                  color: colorScheme.primary,
                ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Personal Finance',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
      Text(
        'Versión 1.0.1 (Stable)',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _buildInfoList(
    ColorScheme colorScheme,
    ThemeData theme,
    BuildContext context,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        _buildInfoItem(
          icon: Icons.public,
          title: 'Sitio Web',
          onTap: () => _launchUrl(context, 'https://jorgegrullondev.com/'),
        ),
        _buildInfoItem(
          icon: Icons.description_outlined,
          title: 'Términos de Servicio',
          onTap: () {},
        ),
        _buildInfoItem(
          icon: Icons.update,
          title: 'Novedades de la Versión',
          onTap:
              () => _launchUrl(
                context,
                'https://github.com/GrullonDev/PersonalFinance',
              ),
        ),
        _buildInfoItem(
          icon: Icons.code_outlined,
          title: 'Licencias de Software',
          onTap: () => showLicensePage(context: context), // Built-in
        ),
      ],
    ),
  );

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) => Column(
    children: [
      ListTile(
        leading: Icon(icon, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
      const Divider(indent: 56),
    ],
  );

  Widget _buildBrandFooter(ColorScheme colorScheme, ThemeData theme) => Column(
    children: [
      Text(
        'Desarrollado con ❤️ por',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'GrullonDev Solutions',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        '© 2026 Personal Finance. Todos los derechos reservados.',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    ],
  );

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showErrorSnackBar(context, 'No se pudo abrir la URL: $url');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Error al intentar abrir la URL');
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
