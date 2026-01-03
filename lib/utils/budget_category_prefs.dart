import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BudgetCategoryPrefs {
  static String _key(String budgetId) => 'budget_categories_\$budgetId';

  static Future<List<String>> load(String budgetId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(budgetId));
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
