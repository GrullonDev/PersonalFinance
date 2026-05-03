import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/core/security/security_preferences.dart';
import 'package:personal_finance/core/services/biometric_service.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Verificar bloqueo al inicio con un pequeño delay para asegurar que el AuthProvider esté listo
    Future.delayed(const Duration(milliseconds: 500), _checkLock);
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

  Future<void> _checkLock() async {
    if (_isLocking || _isAuthenticating) return;

    final AuthProvider auth = context.read<AuthProvider>();
    await auth.syncSessionFromFirebase(notify: false);
    if (!auth.isAuthenticated) return;

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
          setState(() => _isLocking = false);
        }
      } finally {
        // Siempre quitar el flag de autenticación después de la llamada nativa
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
              const Icon(Icons.lock_outline, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Aplicación Bloqueada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _checkLock,
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
                color: Colors.black.withOpacity(0.4),
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
