import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:personal_finance/core/services/navigation_service.dart';
import 'package:personal_finance/core/services/update_policy.dart';
import 'package:personal_finance/core/services/version_service.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

/// Revisa si hay una versión nueva al abrir la app y al volver a ella.
///
/// - Actualización opcional: diálogo "Nueva versión disponible" (si el
///   usuario elige "Más tarde" no se repite en 24 h para esa versión).
/// - Actualización obligatoria: pantalla que bloquea la app hasta actualizar.
///
/// Las versiones se publican en Firebase Remote Config (ver [VersionService]).
class UpdateWatcher extends StatefulWidget {
  const UpdateWatcher({required this.child, super.key});

  final Widget child;

  @override
  State<UpdateWatcher> createState() => _UpdateWatcherState();
}

class _UpdateWatcherState extends State<UpdateWatcher>
    with WidgetsBindingObserver {
  static const String _dismissedKey = 'update_dismissed_version';
  static const String _dismissedAtKey = 'update_dismissed_at';
  static const Duration _minInterval = Duration(minutes: 30);

  DateTime? _lastCheck;
  bool _checking = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Se espera a que termine el arranque (splash/login) antes de avisar.
    Future<void>.delayed(const Duration(seconds: 4), _check);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (!mounted || _checking || _dialogOpen) return;
    final DateTime now = DateTime.now();
    if (_lastCheck != null && now.difference(_lastCheck!) < _minInterval) {
      return;
    }
    if (!getIt.isRegistered<VersionService>()) return;
    _checking = true;
    _lastCheck = now;
    try {
      final UpdateCheck result = await getIt<VersionService>().checkForUpdate();
      if (!mounted) return;
      switch (result.kind) {
        case UpdateKind.none:
          break;
        case UpdateKind.required:
          getIt<NavigationService>().navigatorKey.currentState
              ?.pushNamedAndRemoveUntil(RoutePath.forceUpdate, (_) => false);
        case UpdateKind.optional:
          await _maybeShowDialog(result);
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _maybeShowDialog(UpdateCheck update) async {
    final SharedPreferences prefs = getIt<SharedPreferences>();
    final String version = update.latest.toString();
    final int? dismissedAt = prefs.getInt(_dismissedAtKey);
    if (prefs.getString(_dismissedKey) == version &&
        dismissedAt != null &&
        DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(dismissedAt),
            ) <
            const Duration(hours: 24)) {
      return;
    }

    final BuildContext? navContext =
        getIt<NavigationService>().navigatorKey.currentContext;
    if (navContext == null) return;

    _dialogOpen = true;
    final bool? wantsUpdate = await showDialog<bool>(
      context: navContext,
      builder: (BuildContext ctx) => _UpdateDialog(update: update),
    );
    _dialogOpen = false;

    if (wantsUpdate == true) {
      await launchUrl(
        Uri.parse(update.url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      await prefs.setString(_dismissedKey, version);
      await prefs.setInt(
        _dismissedAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({required this.update});

  final UpdateCheck update;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Icon(Icons.system_update_rounded, color: primary, size: 40),
      title: const Text('¡Nueva versión disponible!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'La versión ${update.latest} ya está lista con mejoras y '
            'correcciones. Actualiza para tener lo último.',
            textAlign: TextAlign.center,
          ),
          if (update.notes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              update.notes.trim(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Más tarde'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Actualizar'),
        ),
      ],
    );
  }
}
