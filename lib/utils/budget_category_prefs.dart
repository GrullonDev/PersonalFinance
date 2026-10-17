import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BudgetCategoryPrefs {
  static String _key(String budgetId) => 'budget_categories_$budgetId';

  /// Versiones anteriores guardaban todos los presupuestos bajo esta misma
  /// clave (el `$` estaba escapado). Se entrega al primer presupuesto que la
  /// lea y se borra, para que los demás detecten sus propias categorías.
  static const String _legacyKey = r'budget_categories_$budgetId';

  static Future<List<String>> load(String budgetId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString(_key(budgetId));
    if (raw == null) {
      raw = prefs.getString(_legacyKey);
      if (raw != null) {
        await prefs.setString(_key(budgetId), raw);
        await prefs.remove(_legacyKey);
      }
    }
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return <String>[];
    }
  }

  static Future<void> save(String budgetId, List<String> categoryIds) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(budgetId), jsonEncode(categoryIds));
  }
}
