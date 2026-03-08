import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance/features/notifications/data/models/notification_preferences_model.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationPreferencesModel> getPreferences();
  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferencesModel prefs,
  );
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  static const String _prefsKey = 'notifications_preferences';
  final SharedPreferences _sharedPrefs;

  NotificationRemoteDataSourceImpl(this._sharedPrefs);

  @override
  Future<NotificationPreferencesModel> getPreferences() async {
    final String? jsonString = _sharedPrefs.getString(_prefsKey);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return NotificationPreferencesModel.fromJson(jsonMap);
      } catch (e) {
        return _getDefaultPreferences();
      }
    }
    return _getDefaultPreferences();
  }

  @override
  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferencesModel prefs,
  ) async {
    final String jsonString = json.encode(prefs.toJson());
    await _sharedPrefs.setString(_prefsKey, jsonString);
    return prefs;
  }

  NotificationPreferencesModel _getDefaultPreferences() =>
      const NotificationPreferencesModel(
        emailEnabled: true,
        pushEnabled: true,
        marketingEnabled: true,
      );
}
