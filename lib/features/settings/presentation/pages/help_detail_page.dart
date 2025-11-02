import 'package:flutter/material.dart';

class HelpDetailPage extends StatelessWidget {
  const HelpDetailPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ayuda/Soporte'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildHelpSection(
          context,
          title: 'Preguntas Frecuentes',
          icon: Icons.question_answer,
          onTap: () {
            // Navegar a preguntas frecuentes
          },
        ),
        _buildHelpSection(
          context,
          title: 'Contactar Soporte',
          icon: Icons.support_agent,
          onTap: () {
            // Navegar a contacto de soporte
          },
        ),
        _buildHelpSection(
          context,
          title: 'Reportar un Problema',
          icon: Icons.bug_report,
          onTap: () {
            // Navegar a reportar problema
          },
        ),
        _buildHelpSection(
          context,
          title: 'Términos y Condiciones',
          icon: Icons.description,
          onTap: () {
            // Navegar a términos y condiciones
          },
        ),
        _buildHelpSection(
          context,
          title: 'Política de Privacidad',
          icon: Icons.privacy_tip,
          onTap: () {
            // Navegar a política de privacidad
          },
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Versión 1.0.0',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    ),
  );

  Widget _buildHelpSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    ),
  );
}
