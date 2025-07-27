import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  static const int maxIndex = 4;  // Número de páginas - 1

  void setIndex(int index) {
    if (_currentIndex != index && index >= 0 && index <= maxIndex) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
