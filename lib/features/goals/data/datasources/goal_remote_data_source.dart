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

  @override
  Future<List<GoalModel>> getGoals() async {
    final Response res = await _api.get('/api/v1/goals');
    if (res.statusCode == 200) {
      final List<dynamic> list =
          res.body.isEmpty
              ? <dynamic>[]
              : jsonDecode(res.body) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(GoalModel.fromJson)
          .toList();
    }
    throw ApiException(
      message: 'Error al obtener metas',
      statusCode: res.statusCode,
    );
  }

  @override
  Future<GoalModel> createGoal(GoalModel goal) async {
    final Response res = await _api.post('/api/v1/goals', body: goal.toJson());
    if (res.statusCode == 201) {
      return GoalModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
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
      return GoalModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw ApiException(message: _detail(res.body), statusCode: res.statusCode);
  }

  @override
  Future<void> deleteGoal(int id) async {
    final Response res = await _api.delete('/api/v1/goals/$id');
    if (res.statusCode == 204) return;
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
