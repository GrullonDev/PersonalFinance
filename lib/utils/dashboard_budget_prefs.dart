import 'package:shared_preferences/shared_preferences.dart';

class DashboardBudgetPrefs {
  static const String _weeklyBudgetKey = 'dashboard_weekly_budget_id';

  static Future<String?> getWeeklyBudgetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_weeklyBudgetKey);
  }

  static Future<void> setWeeklyBudgetId(String budgetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weeklyBudgetKey, budgetId);
  }

  static Future<void> clearWeeklyBudgetId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_weeklyBudgetKey);
  }
}
