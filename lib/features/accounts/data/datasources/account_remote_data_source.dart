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

  @override
  Future<List<AccountModel>> getAccounts() async {
    final Response response = await _apiService.get('/api/v1/accounts');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body) as List;
      return jsonList
          .map((json) => AccountModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        message: 'Failed to load accounts',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<AccountModel> getAccount(String id) async {
    final Response response = await _apiService.get('/api/v1/accounts/$id');

    if (response.statusCode == 200) {
      return AccountModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw ApiException(
        message: 'Failed to load account',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    final Response response = await _apiService.post(
      '/api/v1/accounts',
      body: account.toJson(),
    );

    if (response.statusCode == 201) {
      return AccountModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw ApiException(
        message: 'Failed to create account',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<AccountModel> updateAccount(AccountModel account) async {
    final Response response = await _apiService.put(
      '/api/v1/accounts/${account.id}',
      body: account.toJson(),
    );

    if (response.statusCode == 200) {
      return AccountModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw ApiException(
        message: 'Failed to update account',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    final Response response = await _apiService.delete('/api/v1/accounts/$id');

    if (response.statusCode != 204) {
      throw ApiException(
        message: 'Failed to delete account',
        statusCode: response.statusCode,
      );
    }
  }
}
