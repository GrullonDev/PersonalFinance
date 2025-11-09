import 'dart:convert';

import 'package:http/http.dart' show Response;

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/network/api_service.dart';
import 'package:personal_finance/features/transactions/data/models/transaction_backend_model.dart';

abstract class TransactionBackendRemoteDataSource {
  Future<List<TransactionBackendModel>> list({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? categoriaId,
    String? tipo,
  });
  Future<TransactionBackendModel> getById(int id);
  Future<TransactionBackendModel> create(TransactionBackendModel tx);
  Future<TransactionBackendModel> update(int id, TransactionBackendModel tx);
  Future<void> delete(int id);
}

class TransactionBackendRemoteDataSourceImpl
    implements TransactionBackendRemoteDataSource {
  TransactionBackendRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<List<TransactionBackendModel>> list({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? categoriaId,
    String? tipo,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      if (fechaDesde != null) 'fecha_desde': _fmt(fechaDesde),
      if (fechaHasta != null) 'fecha_hasta': _fmt(fechaHasta),
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
    };
    final Response res = await _api.get(
      '/api/v1/transactions',
      queryParameters: query,
    );
    if (res.statusCode == 200) {
      final dynamic decoded =
          res.body.isEmpty ? <dynamic>[] : jsonDecode(res.body);
      final List<dynamic> list = decoded is List
          ? decoded
          : (decoded is Map<String, dynamic> && decoded['data'] is List
              ? decoded['data'] as List<dynamic>
              : <dynamic>[]);
      return list
          .whereType<Map<String, dynamic>>()
          .map(TransactionBackendModel.fromJson)
          .toList();
    }
    throw ApiException(
      message: 'Error al obtener transacciones',
      statusCode: res.statusCode,
    );
  }

  @override
  Future<TransactionBackendModel> getById(int id) async {
    final Response res = await _api.get('/api/v1/transactions/$id');
    if (res.statusCode == 200) {
      final dynamic decoded = jsonDecode(res.body);
      final Map<String, dynamic> map =
          decoded is Map<String, dynamic>
              ? (decoded['data'] is Map<String, dynamic>
                  ? decoded['data'] as Map<String, dynamic>
                  : decoded)
              : <String, dynamic>{};
      return TransactionBackendModel.fromJson(map);
    }
    throw ApiException(
      message: 'No se pudo obtener la transacción',
      statusCode: res.statusCode,
    );
  }

  @override
  Future<TransactionBackendModel> create(TransactionBackendModel tx) async {
    final Response res = await _api.post(
      '/api/v1/transactions',
      body: tx.toJson(),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final dynamic decoded = jsonDecode(res.body);
      final Map<String, dynamic> map =
          decoded is Map<String, dynamic>
              ? (decoded['data'] is Map<String, dynamic>
                  ? decoded['data'] as Map<String, dynamic>
                  : decoded)
              : <String, dynamic>{};
      return TransactionBackendModel.fromJson(map);
    }
    throw ApiException(message: _detail(res.body), statusCode: res.statusCode);
  }

  @override
  Future<TransactionBackendModel> update(
    int id,
    TransactionBackendModel tx,
  ) async {
    final Response res = await _api.put(
      '/api/v1/transactions/$id',
      body: tx.toJson(),
    );
    if (res.statusCode == 200) {
      final dynamic decoded = jsonDecode(res.body);
      final Map<String, dynamic> map =
          decoded is Map<String, dynamic>
              ? (decoded['data'] is Map<String, dynamic>
                  ? decoded['data'] as Map<String, dynamic>
                  : decoded)
              : <String, dynamic>{};
      return TransactionBackendModel.fromJson(map);
    }
    throw ApiException(message: _detail(res.body), statusCode: res.statusCode);
  }

  @override
  Future<void> delete(int id) async {
    final Response res = await _api.delete('/api/v1/transactions/$id');
    if (res.statusCode == 204) return;
    throw ApiException(message: _detail(res.body), statusCode: res.statusCode);
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
