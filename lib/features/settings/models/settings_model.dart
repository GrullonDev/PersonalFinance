import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel extends ChangeNotifier {
  bool _darkMode = false;

  bool get darkMode => _darkMode;

  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    notifyListeners();
  }
}
