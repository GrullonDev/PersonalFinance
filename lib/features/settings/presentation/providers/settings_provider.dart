import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _darkMode = false;
  String _themeMode = 'Sistema'; // 'Claro', 'Oscuro', 'Sistema'

  Color _primaryColor = Colors.blue;
  String _textSize = 'Mediano';
  bool _animationsEnabled = true;
  String _chartStyle = 'Anillo';

  String _usageType = 'personal';
  bool _isBusinessMode = false;

  bool get darkMode => _darkMode;
  String get themeModeString => _themeMode;

  ThemeMode get themeMode {
    switch (_themeMode) {
      case 'Claro':
        return ThemeMode.light;
      case 'Oscuro':
        return ThemeMode.dark;
      case 'Sistema':
      default:
        return ThemeMode.system;
    }
  }

  Color get primaryColor => _primaryColor;
  String get textSize => _textSize;
  bool get animationsEnabled => _animationsEnabled;
  String get chartStyle => _chartStyle;

  String get usageType => _usageType;
  bool get isBusinessMode => _isBusinessMode;
  bool get canToggleMode => _usageType == 'ambos';

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('dark_mode') ?? false;
    _themeMode = prefs.getString('theme_mode') ?? 'Sistema';

    final int colorValue = prefs.getInt('primary_color') ?? Colors.blue.value;
    _primaryColor = Color(colorValue);

    _textSize = prefs.getString('text_size') ?? 'Mediano';
    _animationsEnabled = prefs.getBool('animations_enabled') ?? true;
    _chartStyle = prefs.getString('chart_style') ?? 'Anillo';

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

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    if (mode == 'Claro') _darkMode = false;
    if (mode == 'Oscuro') _darkMode = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeMode);
    await prefs.setBool('dark_mode', _darkMode);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    _themeMode = _darkMode ? 'Oscuro' : 'Claro';
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setString('theme_mode', _themeMode);
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primary_color', color.value);
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

  Future<void> toggleBusinessMode({required bool value}) async {
    if (!canToggleMode) return;
    _isBusinessMode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_business_mode', _isBusinessMode);
    notifyListeners();
  }
}
