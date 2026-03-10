import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _darkMode = false;

  String _usageType = 'personal';
  bool _isBusinessMode = false;

  bool get darkMode => _darkMode;
  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  String get usageType => _usageType;
  bool get isBusinessMode => _isBusinessMode;
  bool get canToggleMode => _usageType == 'ambos';

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('dark_mode') ?? false;
    _usageType = prefs.getString('usage_type') ?? 'personal';

    if (_usageType == 'negocio') {
      _isBusinessMode = true;
    } else if (_usageType == 'ambos') {
      _isBusinessMode = prefs.getBool('is_business_mode') ?? false;
    } else {
      _isBusinessMode = false;
    }
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    notifyListeners();
  }

  Future<void> toggleBusinessMode({required bool value}) async {
    if (!canToggleMode) return;
    _isBusinessMode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_business_mode', _isBusinessMode);
    notifyListeners();
  }
}
