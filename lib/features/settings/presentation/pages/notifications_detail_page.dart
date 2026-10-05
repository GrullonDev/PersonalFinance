import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_preferences.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/features/notifications/presentation/providers/notification_prefs_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:personal_finance/core/services/notifications/notification_permission_service.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';

class NotificationsDetailPage extends StatelessWidget {
  const NotificationsDetailPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.greenAccent,
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
          return EmptyState(
            title: 'No pudimos cargar tus notificaciones',
            message: provider.error!,
            icon: Icons.notifications_off_outlined,
            action: FilledButton(
              onPressed: provider.load,
              child: const Text('Reintentar'),
            ),
          );
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
            _buildSwitchTile(
              title: 'Alertas de desvío de gasto',
              subtitle:
                  'Te avisamos cuando gastas más de lo habitual, más de lo que '
                  'ganas o cuando se acumulan gastos hormiga',
              value: prefs.budgetAlertsEnabled,
              onChanged: (bool value) async {
                final bool ok = await provider.save(budgetAlertsEnabled: value);
                _feedback(context, ok, provider.error);
              },
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
            if (GetIt.instance.isRegistered<AutoCaptureService>()) ...[
              const Divider(),
              const _AutoCaptureSection(),
            ],
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
    extends State<_NotificationsPermissionBanner>
    with WidgetsBindingObserver {
  final NotificationPermissionService _permissions =
      GetIt.instance<NotificationPermissionService>();

  /// `null` mientras se consulta; luego el estado real del sistema.
  bool? _enabled;

  /// Ya se pidió el permiso y el sistema lo negó: sólo queda ir a Ajustes.
  bool _askedAndDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver de Ajustes del sistema se vuelve a consultar el permiso.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final bool enabled = await _permissions.isEnabled();
    if (mounted) setState(() => _enabled = enabled);
  }

  Future<void> _request() async {
    final bool granted = await _permissions.requestAll();
    if (!mounted) return;
    setState(() {
      _enabled = granted;
      _askedAndDenied = !granted;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(granted ? 'Permiso concedido' : 'Permiso denegado'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled ?? true) return const SizedBox.shrink();
    final bool permanentlyDenied = _askedAndDenied;
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

/// Registro automático de pagos: Google Wallet / bancos en Android y
/// Apple Pay (vía Atajos) en iOS.
class _AutoCaptureSection extends StatefulWidget {
  const _AutoCaptureSection();

  @override
  State<_AutoCaptureSection> createState() => _AutoCaptureSectionState();
}

class _AutoCaptureSectionState extends State<_AutoCaptureSection>
    with WidgetsBindingObserver {
  final AutoCaptureService _service = GetIt.instance<AutoCaptureService>();
  bool _enabled = true;
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver de Ajustes del sistema se revisa si ya se concedió el acceso.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final bool granted = await _service.isAccessGranted();
    if (!mounted) return;
    setState(() {
      _enabled = _service.isEnabled;
      _granted = granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Platform.isIOS;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'REGISTRO AUTOMÁTICO DE PAGOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        SwitchListTile(
          title: Text(
            isIOS
                ? 'Registrar pagos con Apple Pay'
                : 'Registrar pagos automáticamente',
          ),
          subtitle: Text(
            isIOS
                ? 'Cada pago con Apple Pay se registra como gasto con su comercio y categoría.'
                : 'Detecta pagos e ingresos en las notificaciones de Google Wallet, '
                    'tu banco o SMS bancarios y los registra con su categoría.',
          ),
          value: _enabled,
          activeThumbColor: Colors.blue,
          onChanged: (bool value) async {
            await _service.setEnabled(enabled: value);
            await _refresh();
          },
        ),
        if (_enabled && !isIOS && !_granted)
          ListTile(
            leading: const Icon(Icons.lock_open, color: Colors.amber),
            title: const Text('Falta dar acceso a las notificaciones'),
            subtitle: const Text(
              'Android pide que lo autorices manualmente. Sólo leemos '
              'notificaciones con montos de dinero y nunca salen de tu teléfono.',
            ),
            trailing: TextButton(
              onPressed: _service.openAccessSettings,
              child: const Text('Permitir'),
            ),
          ),
        if (_enabled && !isIOS && _granted)
          const ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Acceso concedido'),
            subtitle: Text('Si un pago no se detecta, regístralo manualmente.'),
          ),
        if (_enabled && isIOS)
          ListTile(
            leading: const Icon(Icons.bolt, color: Colors.amber),
            title: const Text('Configura el atajo (una sola vez)'),
            subtitle: const Text(
              'Atajos → Automatización → Nueva → Transacción → elige tus '
              'tarjetas → acción "Abrir URL":\n'
              'personalfinance://pago?monto=[Importe]&comercio=[Comercio]\n'
              'y marca "Ejecutar inmediatamente". Los ingresos se registran '
              'manualmente.',
            ),
            isThreeLine: true,
            trailing: TextButton(
              onPressed: _service.openAccessSettings,
              child: const Text('Abrir Atajos'),
            ),
          ),
      ],
    );
  }
}
