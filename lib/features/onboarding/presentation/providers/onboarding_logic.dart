import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/features/onboarding/domain/entities/onboarding_model.dart';

class OnboardingLogic extends ChangeNotifier {
  int _currentPage = 0;
  bool _isLastPage = false;

  int get currentPage => _currentPage;
  bool get isLastPage => _isLastPage;
  int get totalPages => OnboardingData.items.length;

  void updatePage(int page) {
    _currentPage = page;
    _isLastPage = page == OnboardingData.items.length - 1;
    notifyListeners();
  }

  void nextPage(PageController pageController) {
    if (_currentPage < OnboardingData.items.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skip(PageController pageController) {
    pageController.animateToPage(
      OnboardingData.items.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }
}
