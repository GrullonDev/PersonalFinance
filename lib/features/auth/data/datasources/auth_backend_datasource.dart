import 'dart:convert';

import 'package:http/http.dart' show Response;
import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/network/api_service.dart';
import 'package:personal_finance/features/auth/data/models/request/login_user_request.dart';
import 'package:personal_finance/features/auth/data/models/response/login_user_response.dart';
import 'package:personal_finance/features/auth/data/models/request/register_user_request.dart';
import 'package:personal_finance/features/auth/data/models/response/register_user_response.dart';
import 'package:personal_finance/features/auth/data/models/request/recover_password_request.dart';
import 'package:personal_finance/features/auth/data/models/request/refresh_token_request.dart';
import 'package:personal_finance/features/auth/data/models/request/reset_password_request.dart';
import 'package:personal_finance/features/auth/data/models/response/refresh_token_response.dart';
import 'package:personal_finance/features/auth/data/models/response/current_user_response.dart';

/// Datasource encargado de invocar los endpoints del backend de autenticación.
// ignore_for_file: prefer_const_constructors
class AuthBackendDataSource {
  AuthBackendDataSource(this._apiService);

  final ApiService _apiService;

  Future<RegisterUserResponse> registerUser(RegisterUserRequest request) async {
    final Response httpResponse = await _apiService.post(
      '/api/v1/auth/register',
      body: request.toJson(),
    );

    final dynamic decodedBody =
        httpResponse.body.isNotEmpty ? jsonDecode(httpResponse.body) : null;

    if (httpResponse.statusCode == 201 && decodedBody is Map<String, dynamic>) {
      return RegisterUserResponse.fromJson(decodedBody);
    }

    // FastAPI uses "detail" in error responses: can be string or list.
    final String detailMessage = _extractDetailMessage(decodedBody);
    throw ApiException(
      message: detailMessage,
      statusCode: httpResponse.statusCode,
      data: decodedBody,
    );
  }

  Future<LoginUserResponse> loginUser(LoginUserRequest request) async {
    final Response httpResponse = await _apiService.post(
      '/api/v1/auth/login',
      body: request.toJson(),
    );

    final dynamic decodedBody =
        httpResponse.body.isNotEmpty ? jsonDecode(httpResponse.body) : null;

    if (httpResponse.statusCode == 200 && decodedBody is Map<String, dynamic>) {
      return LoginUserResponse.fromJson(decodedBody);
    }

    // FastAPI uses "detail" in error responses: can be string or list.
    final String detailMessage = _extractDetailMessage(decodedBody);
    throw ApiException(
      message: detailMessage,
      statusCode: httpResponse.statusCode,
      data: decodedBody,
    );
  }

  Future<void> recoverPassword(RecoverPasswordRequest request) async {
    final Response httpResponse = await _apiService.post(
      '/api/v1/auth/forgot-password',
      body: request.toJson(),
    );

    final dynamic decodedBody =
        httpResponse.body.isNotEmpty ? jsonDecode(httpResponse.body) : null;

    if (httpResponse.statusCode == 200) {
      return;
    }

    // FastAPI uses "detail" in error responses: can be string or list.
    final String detailMessage = _extractDetailMessage(decodedBody);
    throw ApiException(
      message: detailMessage,
      statusCode: httpResponse.statusCode,
      data: decodedBody,
    );
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    final Response httpResponse = await _apiService.post(
      '/api/v1/auth/reset-password',
      body: request.toJson(),
    );

    final dynamic decodedBody =
        httpResponse.body.isNotEmpty ? jsonDecode(httpResponse.body) : null;

    if (httpResponse.statusCode == 200) {
      return;
    }

    // FastAPI uses "detail" in error responses: can be string or list.
    final String detailMessage = _extractDetailMessage(decodedBody);
    throw ApiException(
      message: detailMessage,
      statusCode: httpResponse.statusCode,
      data: decodedBody,
    );
  }

  Future<RefreshTokenResponse> refreshToken(RefreshTokenRequest request) async {
    final Response httpResponse = await _apiService.post(
      '/api/v1/auth/refresh-token',
      body: request.toJson(),
    );

    final dynamic decodedBody =
        httpResponse.body.isNotEmpty ? jsonDecode(httpResponse.body) : null;

    if (httpResponse.statusCode == 200 && decodedBody is Map<String, dynamic>) {
      return RefreshTokenResponse.fromJson(decodedBody);
    }

    final String detailMessage = _extractDetailMessage(decodedBody);
    throw ApiException(
      message: detailMessage,
      statusCode: httpResponse.statusCode,
      data: decodedBody,
    );
  }

  Future<CurrentUserResponse> getCurrentUser() async {
    final Response httpResponse = await _apiService.get(
      '/api/v1/users/me',
    );

    final dynamic decodedBody =
        httpResponse.body.isNotEmpty ? jsonDecode(httpResponse.body) : null;

    if (httpResponse.statusCode == 200 && decodedBody is Map<String, dynamic>) {
      return CurrentUserResponse.fromJson(decodedBody);
    }

    final String detailMessage = _extractDetailMessage(decodedBody);
    throw ApiException(
      message: detailMessage,
      statusCode: httpResponse.statusCode,
      data: decodedBody,
    );
  }

  String _extractDetailMessage(dynamic decodedBody) {
    if (decodedBody == null) {
      return 'Error desconocido al procesar la solicitud';
    }
    if (decodedBody is Map<String, dynamic>) {
      final dynamic detail = decodedBody['detail'];
      if (detail is String) {
        return detail;
      }
      if (detail is List) {
        return detail
            .whereType<Map<String, dynamic>>()
            .map((Map<String, dynamic> item) => item['msg']?.toString() ?? '')
            .where((String msg) => msg.isNotEmpty)
            .join('\n')
            .trim();
      }
    }
    return 'Error desconocido al registrar usuario';
  }
}
