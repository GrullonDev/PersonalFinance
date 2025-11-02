import 'package:flutter/material.dart';

class NotificationsDetailPage extends StatefulWidget {
  const NotificationsDetailPage({super.key});

  @override
  State<NotificationsDetailPage> createState() =>
      _NotificationsDetailPageState();
}

class _NotificationsDetailPageState extends State<NotificationsDetailPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _transactionAlerts = true;
  bool _budgetAlerts = true;
  bool _goalAlerts = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notificaciones'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: ListView(
      children: <Widget>[
        _buildSwitchTile(
          title: 'Notificaciones Push',
          subtitle: 'Recibe notificaciones en tu dispositivo',
          value: _pushNotifications,
          onChanged: (bool value) {
            setState(() {
              _pushNotifications = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Notificaciones por Email',
          subtitle: 'Recibe notificaciones en tu correo electrónico',
          value: _emailNotifications,
          onChanged: (bool value) {
            setState(() {
              _emailNotifications = value;
            });
          },
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'TIPOS DE ALERTAS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        _buildSwitchTile(
          title: 'Alertas de Transacciones',
          subtitle: 'Notificaciones sobre nuevas transacciones',
          value: _transactionAlerts,
          onChanged: (bool value) {
            setState(() {
              _transactionAlerts = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Alertas de Presupuesto',
          subtitle:
              'Notificaciones cuando te acercas al límite de tu presupuesto',
          value: _budgetAlerts,
          onChanged: (bool value) {
            setState(() {
              _budgetAlerts = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Alertas de Metas',
          subtitle: 'Notificaciones sobre el progreso de tus metas',
          value: _goalAlerts,
          onChanged: (bool value) {
            setState(() {
              _goalAlerts = value;
            });
          },
        ),
      ],
    ),
  );

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile(
    title: Text(title),
    subtitle: Text(subtitle),
    value: value,
    onChanged: onChanged,
    activeThumbColor: Colors.blue,
  );
}
