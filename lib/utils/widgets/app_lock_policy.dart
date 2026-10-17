import 'package:flutter/widgets.dart';

/// Decide cuándo hay que volver a pedir el desbloqueo biométrico.
///
/// El diálogo de Face ID / huella pasa la app por `inactive` → `resumed`, y
/// en iOS ese `resumed` puede llegar después de que la autenticación ya
/// terminó. Si se bloqueara en cada `resumed`, el propio diálogo volvería a
/// bloquear la app en un ciclo sin fin. Por eso sólo se bloquea cuando la app
/// pasó de verdad a segundo plano (`hidden`/`paused`), y nunca justo después
/// de un desbloqueo exitoso.
class AppLockPolicy {
  AppLockPolicy({
    DateTime Function()? now,
    this.unlockGracePeriod = const Duration(seconds: 2),
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Duration unlockGracePeriod;

  bool _wentToBackground = false;
  DateTime? _lastUnlock;

  /// Registra un cambio de ciclo de vida y devuelve `true` si al volver a
  /// primer plano hay que pedir el desbloqueo.
  bool shouldLockOn(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _wentToBackground = true;
        return false;
      case AppLifecycleState.resumed:
        final wasInBackground = _wentToBackground;
        _wentToBackground = false;
        if (!wasInBackground) return false;
        final lastUnlock = _lastUnlock;
        if (lastUnlock != null &&
            _now().difference(lastUnlock) < unlockGracePeriod) {
          return false;
        }
        return true;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        return false;
    }
  }

  /// Llamar tras un desbloqueo biométrico exitoso.
  void markUnlocked() {
    _lastUnlock = _now();
    _wentToBackground = false;
  }
}
