import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _darkMode = false;
  bool _hideAmounts = false;

  bool get darkMode => _darkMode;
  bool get hideAmounts => _hideAmounts;
  ThemeMode get themeMode {
    if (_themeModeString == 'Oscuro') {
      return ThemeMode.dark;
    } else if (_themeModeString == 'Claro') {
      return ThemeMode.light;
    } else {
      return ThemeMode.system;
    }
  }

  // Business mode — feature not active in current release.
  bool get isBusinessMode => false;
  bool get canToggleMode => false;
  Future<void> toggleBusinessMode({required bool value}) async {}

  // Appearance settings — dynamic theme, text size, animations, chart style.
  Color _primaryColor = const Color(0xFF0E8F5B);
  String _textSize = 'Mediano';
  bool _animationsEnabled = true;
  String _chartStyle = 'Barras';
  String _themeModeString = 'Sistema';

  Color get primaryColor => _primaryColor;
  String get textSize => _textSize;
  bool get animationsEnabled => _animationsEnabled;
  String get chartStyle => _chartStyle;
  String get themeModeString => _themeModeString;

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primary_color', color.toARGB32());
    notifyListeners();
  }

  Future<void> setTextSize(String size) async {
    _textSize = size;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('text_size', size);
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool enabled) async {
    _animationsEnabled = enabled;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animations_enabled', enabled);
    notifyListeners();
  }

  Future<void> setChartStyle(String style) async {
    _chartStyle = style;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('chart_style', style);
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    _themeModeString = mode;
    _darkMode = mode == 'Oscuro';
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
    await prefs.setBool('dark_mode', _darkMode);
    notifyListeners();
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('dark_mode') ?? false;
    _hideAmounts = prefs.getBool('hide_amounts') ?? false;
    final int? colorValue = prefs.getInt('primary_color');
    if (colorValue != null) _primaryColor = Color(colorValue);
    _textSize = prefs.getString('text_size') ?? 'Mediano';
    _animationsEnabled = prefs.getBool('animations_enabled') ?? true;
    _chartStyle = prefs.getString('chart_style') ?? 'Barras';
    _themeModeString = prefs.getString('theme_mode') ?? 'Sistema';
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
