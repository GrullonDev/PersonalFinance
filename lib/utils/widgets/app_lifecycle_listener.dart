import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/core/services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    if (state == AppLifecycleState.resumed) {
      // Al volver a primer plano
      final AuthProvider auth = context.read<AuthProvider>();
      auth.onAppResumed();
      _checkLock();
    }
  }

  Future<void> _checkLock() async {
    if (_isLocking || _isAuthenticating) return;

    final prefs = await SharedPreferences.getInstance();

    // Solo bloqueamos si el onboarding está completo
    final bool onboardingComplete =
        prefs.getBool('onboarding_complete') ?? false;
    if (!onboardingComplete) return;

    // Solo bloqueamos si el usuario está autenticado
    final AuthProvider auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final bool appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;

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
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
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
    return widget.child;
  }
}
