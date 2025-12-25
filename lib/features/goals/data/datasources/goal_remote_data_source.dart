import 'dart:convert';

import 'package:http/http.dart' show Response;

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/network/api_service.dart';
import 'package:personal_finance/features/goals/data/models/goal_model.dart';

abstract class GoalRemoteDataSource {
  Future<List<GoalModel>> getGoals();
  Future<GoalModel> createGoal(GoalModel goal);
  Future<GoalModel> updateGoal(int id, GoalModel goal);
  Future<void> deleteGoal(int id);
}

class GoalRemoteDataSourceImpl implements GoalRemoteDataSource {
  GoalRemoteDataSourceImpl(this._api);
  final ApiService _api;

  List<Map<String, dynamic>> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    if (decoded is Map<String, dynamic>) {
      final dynamic inner =
          decoded['data'] ?? decoded['results'] ?? decoded['items'];
      if (inner is List) {
        return inner.whereType<Map<String, dynamic>>().toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final dynamic inner = decoded['data'];
      if (inner is Map<String, dynamic>) return inner;
      return decoded;
    }
    return <String, dynamic>{};
  }

  @override
  Future<List<GoalModel>> getGoals() async {
    final Response res = await _api.get('/api/v1/goals/');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final dynamic decoded =
          res.body.isEmpty ? <dynamic>[] : jsonDecode(res.body);
      final List<Map<String, dynamic>> list = _extractList(decoded);
      return list.map(GoalModel.fromJson).toList();
    }
    throw ApiException(
      message: 'Error al obtener metas',
      statusCode: res.statusCode,
    );
  }

  @override
  Future<GoalModel> createGoal(GoalModel goal) async {
    final Response res = await _api.post('/api/v1/goals/', body: goal.toJson());
    if (res.statusCode == 201 || res.statusCode == 200) {
      final dynamic decoded =
          res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
      final Map<String, dynamic> map = _extractMap(decoded);
      return GoalModel.fromJson(map);
    }
    throw ApiException(message: _detail(res.body), statusCode: res.statusCode);
  }

  @override
  Future<GoalModel> updateGoal(int id, GoalModel goal) async {
    final Response res = await _api.put(
      '/api/v1/goals/$id',
      body: goal.toJson(),
    );
    if (res.statusCode == 200) {
      final dynamic decoded =
          res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
      final Map<String, dynamic> map = _extractMap(decoded);
      return GoalModel.fromJson(map);
    }
    throw ApiException(message: _detail(res.body), statusCode: res.statusCode);
  }

  @override
  Future<void> deleteGoal(int id) async {
    final Response res = await _api.delete('/api/v1/goals/$id');
    if (res.statusCode >= 200 && res.statusCode < 300) return;
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
              .join('\\n');
        }
      }
    } catch (_) {}
    return 'Error desconocido';
  }
}
