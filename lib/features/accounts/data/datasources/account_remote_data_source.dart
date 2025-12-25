import 'dart:convert';

import 'package:http/http.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/network/api_service.dart';
import 'package:personal_finance/features/accounts/data/models/account_model.dart';

abstract class AccountRemoteDataSource {
  Future<List<AccountModel>> getAccounts();
  Future<AccountModel> getAccount(String id);
  Future<AccountModel> createAccount(AccountModel account);
  Future<AccountModel> updateAccount(AccountModel account);
  Future<void> deleteAccount(String id);
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  AccountRemoteDataSourceImpl(this._apiService);

  final ApiService _apiService;

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

  @override
  Future<List<AccountModel>> getAccounts() async {
    final Response response = await _apiService.get('/api/v1/accounts/');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic decoded =
          response.body.isEmpty ? <dynamic>[] : jsonDecode(response.body);
      final List<Map<String, dynamic>> list = _extractList(decoded);
      return list.map(AccountModel.fromJson).toList();
    }
    throw ApiException(
      message: 'Failed to load accounts',
      statusCode: response.statusCode,
    );
  }

  @override
  Future<AccountModel> getAccount(String id) async {
    final Response response = await _apiService.get('/api/v1/accounts/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic decoded =
          response.body.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(response.body);
      final Map<String, dynamic> map = _extractMap(decoded);
      return AccountModel.fromJson(map);
    }
    throw ApiException(
      message: 'Failed to load account',
      statusCode: response.statusCode,
    );
  }

  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    final Response response = await _apiService.post(
      '/api/v1/accounts/',
      body: account.toJson(),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final dynamic decoded =
          response.body.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(response.body);
      final Map<String, dynamic> map = _extractMap(decoded);
      return AccountModel.fromJson(map);
    }
    throw ApiException(
      message: _detail(response.body),
      statusCode: response.statusCode,
    );
  }

  @override
  Future<AccountModel> updateAccount(AccountModel account) async {
    final Response response = await _apiService.put(
      '/api/v1/accounts/${account.id}',
      body: account.toJson(),
    );
    if (response.statusCode == 200) {
      final dynamic decoded =
          response.body.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(response.body);
      final Map<String, dynamic> map = _extractMap(decoded);
      return AccountModel.fromJson(map);
    }
    throw ApiException(
      message: _detail(response.body),
      statusCode: response.statusCode,
    );
  }

  @override
  Future<void> deleteAccount(String id) async {
    final Response response = await _apiService.delete('/api/v1/accounts/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(
      message: _detail(response.body),
      statusCode: response.statusCode,
    );
  }
}
