import 'package:personal_finance/features/notifications/data/models/notification_preferences_model.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationPreferencesModel> getPreferences();
  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferencesModel prefs,
  );
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl();

  @override
  Future<NotificationPreferencesModel> getPreferences() async {
    return NotificationPreferencesModel(
      emailEnabled: true,
      pushEnabled: true,
      marketingEnabled: true,
    );
  }

  @override
  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferencesModel prefs,
  ) async {
    // Mock update
    return prefs;
  }
}
