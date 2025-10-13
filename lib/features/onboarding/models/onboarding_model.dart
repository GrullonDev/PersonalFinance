import 'package:flutter/foundation.dart';

@immutable
class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.description,
    this.imagePath,
  });

  final String title;
  final String description;
  final String? imagePath;
}

class OnboardingData {
  static const List<OnboardingItem> items = <OnboardingItem>[
    OnboardingItem(
      title: '¡Bienvenido a Personal Finance!',
      description:
          'Tu herramienta perfecta para gestionar tus finanzas personales de manera inteligente y efectiva.',
      imagePath: 'assets/images/onboarding.png',
    ),
    OnboardingItem(
      title: 'Controla tus Gastos',
      description:
          'Registra y categoriza tus gastos e ingresos de forma sencilla. Mantén un seguimiento claro de tu dinero.',
    ),
    OnboardingItem(
      title: 'Establece Metas',
      description:
          'Define objetivos financieros y te ayudaremos a alcanzarlos con un plan personalizado.',
    ),
    OnboardingItem(
      title: 'Toma el Control',
      description: 'Comienza tu viaje hacia la libertad financiera hoy mismo.',
    ),
  ];
}
