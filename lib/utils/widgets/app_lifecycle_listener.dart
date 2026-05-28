import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/core/security/security_preferences.dart';
import 'package:personal_finance/core/services/biometric_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:personal_finance/core/services/security_logger.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';

class AppLifecycleWrapper extends StatefulWidget {
  const AppLifecycleWrapper({required this.child, super.key});

  final Widget child;

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  final _biometricService = BiometricService();
  bool _isLocking = false;
  bool _isAuthenticating = false;
  // True while the app is in the background / app-switcher — hides content.
  bool _isObscured = false;
  int _biometricFailCount = 0;
  DateTime? _lastFailTime;
  bool _isLockedOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLockoutState().then((_) {
      // Verificar bloqueo al inicio con un pequeño delay para asegurar que el AuthProvider esté listo
      Future.delayed(const Duration(milliseconds: 500), _checkLock);
    });
  }

  Future<void> _loadLockoutState() async {
    final (count, lockTime) = await SecurityPreferences.getBiometricLockout();
    setState(() {
      _biometricFailCount = count;
      _lastFailTime = lockTime;
      if (lockTime != null) {
        final diff = DateTime.now().difference(lockTime);
        if (diff.inMinutes < 15) {
          _isLockedOut = true;
          _isLocking = true;
        } else {
          _biometricFailCount = 0;
          _lastFailTime = null;
          _isLockedOut = false;
          SecurityPreferences.saveBiometricLockout(0, null);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Si estamos en medio de una autenticación biométrica, ignoramos el ciclo de vida
    // ya que el diálogo nativo causa transiciones de pausa/resumen.
    if (_isAuthenticating) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App is about to be backgrounded — obscure financial content before
      // the OS captures the app-switcher screenshot.
      setState(() => _isObscured = true);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _isObscured = false);
      final AuthProvider auth = context.read<AuthProvider>();
      auth.onAppResumed();
      _checkLock();
    }
  }

  int get _remainingMinutes {
    if (_lastFailTime == null) return 0;
    final diff = DateTime.now().difference(_lastFailTime!);
    final remaining = 15 - diff.inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  Future<void> _checkLock({bool forceAuth = false}) async {
    final (count, lockTime) = await SecurityPreferences.getBiometricLockout();
    _biometricFailCount = count;
    _lastFailTime = lockTime;

    if (lockTime != null) {
      final diff = DateTime.now().difference(lockTime);
      if (diff.inMinutes < 15) {
        setState(() {
          _isLockedOut = true;
          _isLocking = true;
        });
        return;
      } else {
        setState(() {
          _biometricFailCount = 0;
          _lastFailTime = null;
          _isLockedOut = false;
        });
        await SecurityPreferences.saveBiometricLockout(0, null);
      }
    } else {
      setState(() {
        _isLockedOut = false;
      });
    }

    if (_isAuthenticating) return;
    if (!forceAuth && _isLocking) return;

    final AuthProvider auth = context.read<AuthProvider>();
    await auth.syncSessionFromFirebase(notify: false);
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) return;

    final bool appLockEnabled = await SecurityPreferences.getAppLockEnabled();

    if (appLockEnabled) {
      setState(() {
        _isLocking = true;
        _isAuthenticating = true;
      });

      try {
        final bool authenticated = await _biometricService.authenticate(
          localizedReason:
              'Acceso Protegido: Confirma tu identidad para continuar',
        );

        if (authenticated) {
          setState(() {
            _isLocking = false;
            _biometricFailCount = 0;
            _lastFailTime = null;
            _isLockedOut = false;
          });
          await SecurityPreferences.saveBiometricLockout(0, null);
        } else {
          final now = DateTime.now();
          final newCount = _biometricFailCount + 1;
          final isLocked = newCount >= 3;
          setState(() {
            _biometricFailCount = newCount;
            _lastFailTime = now;
            if (isLocked) {
              _isLockedOut = true;
              SecurityLogger().logSuspiciousActivity('too_many_biometric_fails');
            }
          });
          await SecurityPreferences.saveBiometricLockout(newCount, isLocked ? now : null);
        }
      } finally {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocking) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isLockedOut ? Icons.gpp_bad_outlined : Icons.lock_outline,
                size: 80,
                color: _isLockedOut ? Colors.redAccent : Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                _isLockedOut ? 'Bloqueo de Seguridad' : 'Aplicación Bloqueada',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (_isLockedOut) ...[
                Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Demasiados intentos fallidos.\nPor seguridad, la app está bloqueada temporalmente.\nIntenta de nuevo en $_remainingMinutes minutos.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                if (_lastFailTime != null && DateTime.now().difference(_lastFailTime!).inMinutes >= 15) {
                  setState(() {
                    _biometricFailCount = 0;
                    _isLockedOut = false;
                  });
                  await SecurityPreferences.saveBiometricLockout(0, null);
                }
                _checkLock(forceAuth: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Verificar estado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => _checkLock(forceAuth: true),
              icon: const Icon(Icons.fingerprint),
              label: const Text('Desbloquear ahora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// Obscure financial content while the app is in the background so that
// the OS app-switcher screenshot does not capture sensitive data.
// On Android, FLAG_SECURE in MainActivity blocks the screenshot at the
// system level; this blur is an additional defense for iOS and older Android.
if (_isObscured) {
  return Stack(
    children: [
      widget.child,
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return widget.child;
  }
}
