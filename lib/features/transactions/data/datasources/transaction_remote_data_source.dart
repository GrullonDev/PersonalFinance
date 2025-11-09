import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/network/api_service.dart';
import 'package:personal_finance/features/transactions/data/models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> getTransaction(String id);
  Future<TransactionModel> createTransaction(TransactionModel transaction);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  TransactionRemoteDataSourceImpl(this._apiService);

  final ApiService _apiService;

  dynamic _handleResponse(http.Response response) {
    // Acepta 2xx como éxito; DELETE puede devolver 204 sin cuerpo
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return null;
      }
    }
    throw ApiException(
      message: 'Request failed with status: ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

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
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final http.Response response = await _apiService.get(
        '/api/v1/transactions',
      );
      final dynamic decoded = _handleResponse(response);
      final List<Map<String, dynamic>> list = _extractList(decoded);
      return list.map(TransactionModel.fromJson).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch transactions: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TransactionModel> getTransaction(String id) async {
    try {
      final http.Response response = await _apiService.get(
        '/api/v1/transactions/$id',
      );
      final dynamic decoded = _handleResponse(response);
      final Map<String, dynamic> map = _extractMap(decoded);
      return TransactionModel.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch transaction: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TransactionModel> createTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final http.Response response = await _apiService.post(
        '/api/v1/transactions',
        body: transaction.toJson(),
      );
      final dynamic decoded = _handleResponse(response);
      final Map<String, dynamic> map = _extractMap(decoded);
      return TransactionModel.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create transaction: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final http.Response response = await _apiService.put(
        '/api/v1/transactions/${transaction.id}',
        body: transaction.toJson(),
      );
      final dynamic decoded = _handleResponse(response);
      final Map<String, dynamic> map = _extractMap(decoded);
      return TransactionModel.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update transaction: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      final http.Response response = await _apiService.delete(
        '/api/v1/transactions/$id',
      );
      _handleResponse(response); // valida status; ignora cuerpo
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete transaction: $e',
        statusCode: 500,
      );
    }
  }
}
