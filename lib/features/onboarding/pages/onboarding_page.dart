import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/features/onboarding/models/onboarding_page_model.dart';
import 'package:personal_finance/features/onboarding/widgets/onboarding_content.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageModel> _pages = const <OnboardingPageModel>[
    OnboardingPageModel(
      title: 'Tu viaje financiero\nempieza aquí',
      description:
          'Toma el control de tus finanzas con nuestra app fácil de usar. Registra tus gastos, crea presupuestos y alcanza tus metas financieras',
      showImage: true,
    ),
    OnboardingPageModel(
      title: 'Tu viaje financiero\nempieza aquí',
      description:
          'Toma el control de tus finanzas con nuestra app fácil de usar. Registra tus gastos, crea presupuestos y alcanza tus metas financieras',
      icon: '💼',
    ),
    OnboardingPageModel(
      title: 'Tu viaje financiero\nempieza aquí',
      description:
          'Toma el control de tus finanzas con nuestra app fácil de usar. Registra tus gastos, crea presupuestos y alcanza tus metas financieras',
      icon: '🎯',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(RoutePath.login);
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[50],
    body: SafeArea(
      child: Column(
        children: <Widget>[
          // Skip button (visible from page 2 onwards)
          if (_currentPage > 0)
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text(
                  'Saltar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 48),

          // PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder:
                  (BuildContext context, int index) => OnboardingContent(
                    page: _pages[index],
                    isFirstPage: index == 0,
                  ),
            ),
          ),

          // Page indicators (visible from page 2 onwards)
          if (_currentPage > 0) ...<Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                _pages.length,
                (int index) => _buildPageIndicator(index),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Start button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Empezar' : 'Empezar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Bottom spacing
          SizedBox(height: _currentPage > 0 ? 16 : 40),
        ],
      ),
    ),
  );

  Widget _buildPageIndicator(int index) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    width: _currentPage == index ? 24 : 8,
    height: 8,
    decoration: BoxDecoration(
      color: _currentPage == index ? Colors.blue : Colors.grey[300],
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
