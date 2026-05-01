import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _darkMode = false;
  bool _hideAmounts = false;

  bool get darkMode => _darkMode;
  bool get hideAmounts => _hideAmounts;
  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('dark_mode') ?? false;
    _hideAmounts = prefs.getBool('hide_amounts') ?? false;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    notifyListeners();
  }

  Future<void> toggleHideAmounts() async {
    _hideAmounts = !_hideAmounts;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_amounts', _hideAmounts);
    notifyListeners();
  }
}
