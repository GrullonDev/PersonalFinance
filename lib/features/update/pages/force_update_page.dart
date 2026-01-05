import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:personal_finance/core/presentation/widgets/premium_background.dart';
import 'package:personal_finance/core/presentation/widgets/glass_container.dart';

class ForceUpdatePage extends StatelessWidget {
  final String storeUrl;

  const ForceUpdatePage({required this.storeUrl, super.key});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(storeUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        // Fallback or log error
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false, // Prevents going back
    child: Scaffold(
      body: PremiumBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassContainer(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.system_update_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡Nueva actualización!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hemos lanzado una nueva versión con mejoras importantes. Para seguir disfrutando de la mejor experiencia, por favor actualiza la aplicación.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _launchURL,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Actualizar ahora',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
