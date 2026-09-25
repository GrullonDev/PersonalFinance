import 'package:flutter/material.dart';
import 'package:personal_finance/utils/app_theme_preset.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // ── Theme ──────────────────────────────────────────────────────────────────

  String _selectedThemeId = 'violeta';
  String get selectedThemeId => _selectedThemeId;

  // Derived from the selected preset so the rest of the app doesn't break
  Color get primaryColor => AppThemePreset.getById(_selectedThemeId).primary;

  // Always ThemeMode.light: the app controls its own theme regardless of the
  // device OS setting. Dark themes are expressed via the preset's ThemeData.
  ThemeMode get themeMode => ThemeMode.light;

  // Legacy helpers kept for any existing callers
  bool get darkMode => AppThemePreset.getById(_selectedThemeId).isDark;
  String get themeModeString =>
      AppThemePreset.getById(_selectedThemeId).isDark ? 'Oscuro' : 'Claro';

  Future<void> setThemeId(String id) async {
    _selectedThemeId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme_id', id);
    notifyListeners();
  }

  // ── Other appearance ────────────────────────────────────────────────────────

  bool _hideAmounts = false;
  String _textSize = 'Mediano';
  bool _animationsEnabled = true;
  String _chartStyle = 'Barras';

  bool get hideAmounts => _hideAmounts;
  String get textSize => _textSize;
  bool get animationsEnabled => _animationsEnabled;
  String get chartStyle => _chartStyle;

  // ── Business mode (not active in current release) ──────────────────────────
  bool get isBusinessMode => false;
  bool get canToggleMode => false;
  Future<void> toggleBusinessMode({required bool value}) async {}

  // ── Setters ─────────────────────────────────────────────────────────────────

  Future<void> setTextSize(String size) async {
    _textSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('text_size', size);
    notifyListeners();
  }

  Future<void> setAnimationsEnabled({required bool enabled}) async {
    _animationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animations_enabled', enabled);
    notifyListeners();
  }

  Future<void> setChartStyle(String style) async {
    _chartStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chart_style', style);
    notifyListeners();
  }

  Future<void> toggleHideAmounts() async {
    _hideAmounts = !_hideAmounts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_amounts', _hideAmounts);
    notifyListeners();
  }

  // Legacy setters — map old values to nearest preset so no call-site breaks
  Future<void> setThemeMode(String mode) async {
    if (mode == 'Oscuro') {
      await setThemeId('noche');
    } else {
      await setThemeId('violeta');
    }
  }

  Future<void> setPrimaryColor(Color color) async {
    final candidates = AppThemePreset.all.where((p) => !p.isPremium).toList();
    AppThemePreset? closest;
    double minDist = double.infinity;
    for (final p in candidates) {
      final dist = (p.primary.r - color.r).abs() +
          (p.primary.g - color.g).abs() +
          (p.primary.b - color.b).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = p;
      }
    }
    if (closest != null) await setThemeId(closest.id);
  }

  Future<void> toggleDarkMode() async {
    final current = AppThemePreset.getById(_selectedThemeId);
    await setThemeId(current.isDark ? 'violeta' : 'noche');
  }

  // ── Init ────────────────────────────────────────────────────────────────────

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _hideAmounts = prefs.getBool('hide_amounts') ?? false;
    _textSize = prefs.getString('text_size') ?? 'Mediano';
    _animationsEnabled = prefs.getBool('animations_enabled') ?? true;
    _chartStyle = prefs.getString('chart_style') ?? 'Barras';

    // Try the new key first, then migrate from old keys.
    final savedId = prefs.getString('selected_theme_id');
    if (savedId != null && AppThemePreset.all.any((t) => t.id == savedId)) {
      _selectedThemeId = savedId;
    } else {
      _selectedThemeId = _migrateOldSettings(prefs);
      await prefs.setString('selected_theme_id', _selectedThemeId);
    }

    notifyListeners();
  }

  String _migrateOldSettings(SharedPreferences prefs) {
    final oldMode = prefs.getString('theme_mode') ?? 'Claro';
    if (oldMode == 'Oscuro') return 'noche';

    final oldColorValue = prefs.getInt('primary_color');
    if (oldColorValue == null) return 'violeta';

    final c = Color(oldColorValue);
    // Map the stored ARGB to the closest free preset by dominant channel.
    if (c.g > c.r && c.g > c.b) return 'esmeralda';
    if (c.b > c.r && c.b > c.g) return 'cielo';
    return 'violeta';
  }
}
