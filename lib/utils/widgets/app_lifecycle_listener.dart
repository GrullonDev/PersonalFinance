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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Verificar bloqueo al inicio
    _checkLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Al volver a primer plano
      final AuthProvider auth = context.read<AuthProvider>();
      auth.onAppResumed();
      _checkLock();
    }
  }

  Future<void> _checkLock() async {
    if (_isLocking) return;

    final prefs = await SharedPreferences.getInstance();
    final bool appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;

    if (appLockEnabled) {
      setState(() => _isLocking = true);
      final bool authenticated = await _biometricService.authenticate(
        localizedReason:
            'Acceso Protegido: Confirma tu identidad para continuar',
      );

      if (!authenticated) {
        // Si no se autentica, podemos re-intentar o salir
        // Por ahora, solo evitamos quitar el estado de bloqueo
        // En una app real podrías mostrar un botón de "Reintentar"
        _checkLock();
      } else {
        setState(() => _isLocking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocking) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
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
        ),
      );
    }
    return widget.child;
  }
}
