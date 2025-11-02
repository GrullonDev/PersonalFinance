import 'dart:convert';

import 'package:http/http.dart' show Response;

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/network/api_service.dart';
import 'package:personal_finance/features/budgets/data/models/budget_model.dart';

abstract class BudgetRemoteDataSource {
  Future<List<BudgetModel>> getBudgets();
  Future<BudgetModel> createBudget(BudgetModel budget);
  Future<BudgetModel> updateBudget(int id, BudgetModel budget);
  Future<void> deleteBudget(int id);
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  BudgetRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<List<BudgetModel>> getBudgets() async {
    final Response res = await _api.get('/api/v1/budgets');
    if (res.statusCode == 200) {
      final List<dynamic> list =
          res.body.isEmpty
              ? <dynamic>[]
              : jsonDecode(res.body) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(BudgetModel.fromJson)
          .toList();
    }
    throw ApiException(
      message: 'Error al obtener presupuestos',
      statusCode: res.statusCode,
    );
  }

  @override
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    final Response res = await _api.post(
      '/api/v1/budgets',
      body: budget.toJson(),
    );
    if (res.statusCode == 201) {
      return BudgetModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw ApiException(message: _detail(res.body), statusCode: res.statusCode);
  }

  @override
  Future<BudgetModel> updateBudget(int id, BudgetModel budget) async {
    final Response res = await _api.put(
      '/api/v1/budgets/$id',
      body: budget.toJson(),
    );
    if (res.statusCode == 200) {
      return BudgetModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw ApiException(message: _detail(res.body), statusCode: res.statusCode);
  }

  @override
  Future<void> deleteBudget(int id) async {
    final Response res = await _api.delete('/api/v1/budgets/$id');
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
              .join('\n');
        }
      }
    } catch (_) {}
    return 'Error desconocido';
  }
}
