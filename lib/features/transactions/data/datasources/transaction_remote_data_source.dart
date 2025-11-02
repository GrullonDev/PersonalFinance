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

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException(
        message: 'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final http.Response response = await _apiService.get(
        '/api/v1/transactions',
      );
      final Map<String, dynamic> data = _handleResponse(response);
      return (data['data'] as List)
          .map(
            (item) => TransactionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
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
      final Map<String, dynamic> data = _handleResponse(response);
      return TransactionModel.fromJson(data['data'] as Map<String, dynamic>);
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
      final Map<String, dynamic> data = _handleResponse(response);
      return TransactionModel.fromJson(data['data'] as Map<String, dynamic>);
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
      final Map<String, dynamic> data = _handleResponse(response);
      return TransactionModel.fromJson(data['data'] as Map<String, dynamic>);
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
      _handleResponse(response);
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
