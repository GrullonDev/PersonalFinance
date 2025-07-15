import 'package:flutter/material.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_OnboardStep> _steps = const <_OnboardStep>[
    _OnboardStep(title: 'Registra tus gastos', description: 'Añade transacciones de forma rápida y sencilla.'),
    _OnboardStep(title: 'Visualiza tu progreso', description: 'Consulta tu balance diario, semanal o mensual.'),
    _OnboardStep(title: 'Aprende consejos', description: 'Recibe tips financieros personalizados cada día.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.savings, size: 80, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 20),
                          Text(step.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Text(step.description, textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: <Widget>[
                    if (_index > 0)
                      TextButton(
                        onPressed: () {
                          _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                        child: const Text('Atrás'),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        if (_index == _steps.length - 1) {
                          Navigator.pushReplacementNamed(context, RoutePath.login);
                        } else {
                          _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                      child: Text(_index == _steps.length - 1 ? 'Comenzar' : 'Siguiente'),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      );
}

class _OnboardStep {
  final String title;
  final String description;
  const _OnboardStep({required this.title, required this.description});
}
