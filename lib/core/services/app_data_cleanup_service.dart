import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/core/security/auth_session_storage.dart';

/// Clears locally cached user data on logout or account deletion.
class AppDataCleanupService {
  AppDataCleanupService._();

  static const List<String> _hiveBoxesToClear = <String>[
    'expenses',
    'incomes',
    'alerts',
    'pending_actions',
    'transactions',
    'sync_operations',
  ];

  static const String _budgetCategoryPrefix = 'budget_categories_';
  static const String _hydratedPrefix = 'quick_finance_hydrated_';
  static const String _lastSyncPrefix = 'quick_finance_last_sync_at_';

  static Future<void> clearUserScopedData({String? userId}) async {
    await Future.wait(_hiveBoxesToClear.map(_clearHiveBox));

    final prefs = await SharedPreferences.getInstance();
    final keysToRemove =
        prefs.getKeys().where((key) {
          if (key.startsWith(_budgetCategoryPrefix)) return true;
          if (key.startsWith(_hydratedPrefix)) return true;
          if (key.startsWith(_lastSyncPrefix)) return true;
          if (userId != null && key.contains(userId)) return true;
          return false;
        }).toList();

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    await AuthSessionStorage.clear();
  }

  static Future<void> _clearHiveBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) return;
    await Hive.box<dynamic>(boxName).clear();
  }
}
