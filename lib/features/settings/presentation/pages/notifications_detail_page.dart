import 'package:flutter/material.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_preferences.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/features/notifications/presentation/providers/notification_prefs_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsDetailPage extends StatelessWidget {
  const NotificationsDetailPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notificaciones'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: Consumer<NotificationPrefsProvider>(
      builder: (BuildContext context, NotificationPrefsProvider provider, _) {
        if (provider.loading && provider.prefs == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null && provider.prefs == null) {
          return Center(child: Text(provider.error!));
        }
        final NotificationPreferences prefs = provider.prefs!;
        return ListView(
          children: <Widget>[
            const _NotificationsPermissionBanner(),
            _buildSwitchTile(
              title: 'Notificaciones Push',
              subtitle: 'Recibe notificaciones en tu dispositivo',
              value: prefs.pushEnabled,
              onChanged: (bool value) async {
                final bool ok = await provider.save(push: value);
                _feedback(context, ok, provider.error);
              },
            ),
            _buildSwitchTile(
              title: 'Notificaciones por Email',
              subtitle: 'Recibe notificaciones en tu correo electrónico',
              value: prefs.emailEnabled,
              onChanged: (bool value) async {
                final bool ok = await provider.save(email: value);
                _feedback(context, ok, provider.error);
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
            // Marketing as example extra alerts toggle
            _buildSwitchTile(
              title: 'Marketing',
              subtitle: 'Recibe correos de marketing',
              value: prefs.marketingEnabled,
              onChanged: (bool value) async {
                final bool ok = await provider.save(marketing: value);
                _feedback(context, ok, provider.error);
              },
            ),
          ],
        );
      },
    ),
  );

  static void _feedback(BuildContext context, bool ok, String? error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Preferencias guardadas' : (error ?? 'Error al guardar'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Widget _buildSwitchTile({
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

class _NotificationsPermissionBanner extends StatefulWidget {
  const _NotificationsPermissionBanner();

  @override
  State<_NotificationsPermissionBanner> createState() =>
      _NotificationsPermissionBannerState();
}

class _NotificationsPermissionBannerState
    extends State<_NotificationsPermissionBanner> {
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final PermissionStatus s = await Permission.notification.status;
    if (mounted) setState(() => _status = s);
  }

  Future<void> _request() async {
    final PermissionStatus s = await Permission.notification.request();
    if (mounted) setState(() => _status = s);
    if (!mounted) return;
    final bool granted = s.isGranted || s.isLimited;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(granted ? 'Permiso concedido' : 'Permiso denegado'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null || _status!.isGranted || _status!.isLimited) {
      return const SizedBox.shrink();
    }
    final bool permanentlyDenied = _status!.isPermanentlyDenied;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.notifications_active, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              permanentlyDenied
                  ? 'Activa las notificaciones desde Ajustes para recibir alertas.'
                  : 'Permite las notificaciones para recibir alertas.',
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              if (permanentlyDenied) {
                await openAppSettings();
              } else {
                await _request();
              }
            },
            child: Text(permanentlyDenied ? 'Abrir ajustes' : 'Permitir'),
          ),
        ],
      ),
    );
  }
}
