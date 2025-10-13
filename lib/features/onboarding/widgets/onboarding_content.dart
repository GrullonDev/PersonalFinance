import 'package:flutter/material.dart';

import 'package:personal_finance/features/onboarding/models/onboarding_page_model.dart';

class OnboardingContent extends StatelessWidget {
  final OnboardingPageModel page;
  final bool isFirstPage;

  const OnboardingContent({
    required this.page,
    this.isFirstPage = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Image or Icon
        if (page.showImage)
          _buildIllustration()
        else if (page.icon != null)
          _buildIconSection(),

        const SizedBox(height: 40),

        // Title
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 16),

        // Description
        Text(
          page.description,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
        ),

        const SizedBox(height: 40),
      ],
    ),
  );

  Widget _buildIllustration() => Container(
    width: 240,
    height: 240,
    decoration: BoxDecoration(
      color: Colors.orange.shade200,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Simulación de ilustración simple - cabeza
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037),
              borderRadius: BorderRadius.circular(60),
            ),
          ),
          const SizedBox(height: 12),
          // Cuerpo
          Container(
            width: 70,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00695C),
              borderRadius: BorderRadius.circular(35),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildIconSection() => Column(
    children: <Widget>[
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                page.icon ?? '💰',
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Controla tus Gastos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra cada transacción para saber a\ndónde va tu dinero.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
