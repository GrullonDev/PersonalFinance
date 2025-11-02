import 'dart:convert';

import 'package:http/http.dart' show Response;
import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/network/api_service.dart';
import 'package:personal_finance/features/profile/data/models/profile_me_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileMeModel> getMe();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<ProfileMeModel> getMe() async {
    final Response res = await _api.get('/api/v1/profiles/me');
    final dynamic decoded =
        res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode == 200 && decoded is Map<String, dynamic>) {
      return ProfileMeModel.fromJson(decoded);
    }

    final String message = _detail(decoded);
    throw ApiException(message: message, statusCode: res.statusCode);
  }

  String _detail(dynamic decoded) {
    try {
      if (decoded == null) return 'Error desconocido';
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

