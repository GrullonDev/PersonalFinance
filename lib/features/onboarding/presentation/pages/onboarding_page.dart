import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance/core/presentation/widgets/glass_container.dart';
import 'package:personal_finance/core/presentation/widgets/premium_background.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'package:personal_finance/utils/responsive.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_OnboardStep> _steps = <_OnboardStep>[
    const _OnboardStep(titleKey: 'step1Title', descriptionKey: 'step1Desc'),
    const _OnboardStep(titleKey: 'step2Title', descriptionKey: 'step2Desc'),
    const _OnboardStep(titleKey: 'step3Title', descriptionKey: 'step3Desc'),
  ];

  @override
  Widget build(BuildContext context) => PremiumBackground(
    child: SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (int i) => setState(() => _index = i),
              itemCount: _steps.length,
              itemBuilder: (BuildContext context, int i) {
                final _OnboardStep step = _steps[i];
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: context.isMobile ? double.infinity : 600,
                      ),
                      child: GlassContainer(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.isMobile ? 24 : 48,
                          vertical: context.isMobile ? 48 : 64,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.savings,
                              size: 100,
                              color: Colors.blue.shade300,
                            ),
                            const SizedBox(height: 32),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.translate(step.titleKey),
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.translate(step.descriptionKey),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: context.isMobile ? double.infinity : 600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: <Widget>[
                  // Indicators
                  Row(
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _index == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color:
                              _index == index
                                  ? Colors.blue.shade300
                                  : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_index > 0)
                    TextButton(
                      onPressed: () {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.back,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (_index == _steps.length - 1) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_complete', true);
                        if (mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            RoutePath.login,
                          );
                        }
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _index == _steps.length - 1
                          ? AppLocalizations.of(context)!.getStarted
                          : AppLocalizations.of(context)!.next,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OnboardStep {
  final String titleKey;
  final String descriptionKey;
  const _OnboardStep({required this.titleKey, required this.descriptionKey});
}
