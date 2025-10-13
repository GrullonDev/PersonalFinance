import 'package:flutter/material.dart';
import 'package:personal_finance/features/onboarding/logic/onboarding_logic.dart';
import 'package:personal_finance/features/onboarding/models/onboarding_model.dart';
import 'package:provider/provider.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OnboardingLogic logic = context.watch<OnboardingLogic>();

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),

          // PageView with onboarding content
          PageView.builder(
            controller: _pageController,
            onPageChanged: logic.updatePage,
            itemCount: OnboardingData.items.length,
            itemBuilder: (BuildContext context, int index) {
              final OnboardingItem item = OnboardingData.items[index];
              return _OnboardingPage(item: item);
            },
          ),

          // Navigation buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (!logic.isLastPage)
                    TextButton(
                      onPressed: () => logic.skip(_pageController),
                      child: const Text('Saltar'),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: () {
                      if (logic.isLastPage) {
                        logic.completeOnboarding().then((_) {
                          // TODO: Navegar a la siguiente pantalla
                        });
                      } else {
                        logic.nextPage(_pageController);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(logic.isLastPage ? 'Comenzar' : 'Siguiente'),
                  ),
                ],
              ),
            ),
          ),

          // Page indicator
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                logic.totalPages,
                (int index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        index == logic.currentPage
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.item});

  final OnboardingItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (item.imagePath != null)
          Expanded(
            flex: 3,
            child: Image.asset(item.imagePath!, fit: BoxFit.contain),
          )
        else
          const Spacer(flex: 3),
        Expanded(
          flex: 2,
          child: Column(
            children: <Widget>[
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                item.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
