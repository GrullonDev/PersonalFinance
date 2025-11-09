import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BudgetCategoryPrefs {
  static String _key(int budgetId) => 'budget_categories_\$budgetId';

  static Future<List<int>> load(int budgetId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(budgetId));
    if (raw == null || raw.isEmpty) return <int>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<int>().toList();
    } catch (_) {
      return <int>[];
    }
  }

  static Future<void> save(int budgetId, List<int> categoryIds) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(budgetId), jsonEncode(categoryIds));
  }
}
