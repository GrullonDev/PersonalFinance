import 'dart:convert';

import 'package:http/http.dart' show Response;

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/network/api_service.dart';
import 'package:personal_finance/features/notifications/data/models/notification_preferences_model.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationPreferencesModel> getPreferences();
  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferencesModel prefs,
  );
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<NotificationPreferencesModel> getPreferences() async {
    final Response res = await _api.get('/api/v1/notifications/preferences');
    if (res.statusCode == 200) {
      final dynamic decoded = jsonDecode(res.body);
      final Map<String, dynamic> map =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      return NotificationPreferencesModel.fromJson(
        map['data'] is Map<String, dynamic>
            ? map['data'] as Map<String, dynamic>
            : map,
      );
    }
    throw ApiException(
      message: 'No se pudieron obtener las preferencias',
      statusCode: res.statusCode,
    );
  }

  @override
  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferencesModel prefs,
  ) async {
    final Response res = await _api.put(
      '/api/v1/notifications/preferences',
      body: prefs.toJson(),
    );
    if (res.statusCode == 200) {
      final dynamic decoded = jsonDecode(res.body);
      final Map<String, dynamic> map =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      return NotificationPreferencesModel.fromJson(
        map['data'] is Map<String, dynamic>
            ? map['data'] as Map<String, dynamic>
            : map,
      );
    }
    throw ApiException(message: _detail(res.body), statusCode: res.statusCode);
  }

  String _detail(String body) {
    try {
      final dynamic decoded = body.isEmpty ? null : jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final dynamic d = decoded['detail'];
        if (d is String) return d;
        if (d is List) {
          return d
              .whereType<Map<String, dynamic>>()
              .map((Map<String, dynamic> e) => e['msg']?.toString() ?? '')
              .where((String e) => e.isNotEmpty)
              .join('\n');
        }
      }
    } catch (_) {}
    return 'Error desconocido';
  }
}
