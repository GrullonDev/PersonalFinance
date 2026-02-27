import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Damos un tiempo mínimo para que la animación del Splash se vea y la UI respire
      await Future<void>.delayed(const Duration(seconds: 2));

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool onboardingComplete =
          prefs.getBool('onboarding_complete') ?? false;

      if (!mounted) return;

      if (onboardingComplete) {
        final AuthProvider auth = context.read<AuthProvider>();

        // Esperamos a que los servicios de fondo se inicialicen con un timeout razonable
        try {
          await auth.onAppResumed().timeout(const Duration(seconds: 15));
        } catch (e) {
          debugPrint('Session restore timeout or error (continuing...): $e');
        }

        if (!mounted) return;

        if (auth.isAuthenticated) {
          Navigator.of(context).pushReplacementNamed(RoutePath.dashboard);
        } else {
          // Si no está autenticado, vamos al login
          Navigator.of(context).pushReplacementNamed(RoutePath.login);
        }
      } else {
        Navigator.of(context).pushReplacementNamed(RoutePath.onboarding);
      }
    } catch (e) {
      debugPrint('Error in _bootstrap: $e');
      if (mounted) {
        // En caso de error crítico, ir al login por seguridad
        Navigator.of(context).pushReplacementNamed(RoutePath.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.primary,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.asset(
              'assets/logo.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Personal Finance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu compañero financiero',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    ),
  );
}
