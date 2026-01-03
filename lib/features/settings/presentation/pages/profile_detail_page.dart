import 'package:flutter/material.dart';

class ProfileDetailPage extends StatelessWidget {
  const ProfileDetailPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Perfil'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Información Personal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildProfileField(
            context,
            label: 'Nombre',
            value: 'Usuario',
            icon: Icons.person,
          ),
          _buildProfileField(
            context,
            label: 'Correo electrónico',
            value: 'usuario@ejemplo.com',
            icon: Icons.email,
          ),
          _buildProfileField(
            context,
            label: 'Teléfono',
            value: '+1234567890',
            icon: Icons.phone,
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Lógica para editar perfil
              },
              child: const Text('Editar Perfil'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildProfileField(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: <Widget>[
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ],
    ),
  );
}
