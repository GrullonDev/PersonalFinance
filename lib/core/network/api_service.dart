import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio base para realizar peticiones HTTP reutilizables en la aplicación.
class ApiService {
  ApiService({http.Client? client, SharedPreferences? prefs})
    : _client = client ?? http.Client(),
      _prefs = prefs;

  final http.Client _client;
  final SharedPreferences? _prefs;

  String get _baseUrl {
    final String? url = dotenv.env['API_BASE_URL']?.trim();
    if (url == null || url.isEmpty) {
      throw StateError(
        'API_BASE_URL no está configurado. '
        'Asegúrate de cargar el archivo .env antes de usar ApiService.',
      );
    }
    // Validar esquema
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null || (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      throw StateError('API_BASE_URL inválido: use http(s)://');
    }
    // Normaliza evitando barra final para prevenir // al construir URIs
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  bool get _isNgrok => _baseUrl.contains('ngrok');

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final String normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath').replace(
      queryParameters: queryParameters?.map(
        (String key, dynamic value) =>
            MapEntry<String, String>(key, value.toString()),
      ),
    );
  }

  Future<http.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final Uri uri = _buildUri(path, queryParameters);
    final http.Response response = await _client.get(
      uri,
      headers: _withAuthHeaders(headers),
    );
    _logRequest('GET', uri, headers: headers);
    _logResponse(response);
    return response;
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final Uri uri = _buildUri(path, queryParameters);
    final http.Response response = await _client.post(
      uri,
      headers: _withJsonHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _logRequest('POST', uri, headers: headers, body: body);
    _logResponse(response);
    return response;
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final Uri uri = _buildUri(path, queryParameters);
    final http.Response response = await _client.put(
      uri,
      headers: _withJsonHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _logRequest('PUT', uri, headers: headers, body: body);
    _logResponse(response);
    return response;
  }

  Future<http.Response> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final Uri uri = _buildUri(path, queryParameters);
    final http.Response response = await _client.delete(
      uri,
      headers: _withJsonHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _logRequest('DELETE', uri, headers: headers, body: body);
    _logResponse(response);
    return response;
  }

  Map<String, String> _withJsonHeaders(Map<String, String>? headers) =>
      <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_isNgrok) 'ngrok-skip-browser-warning': 'true',
        if (_prefs?.getString('access_token') != null)
          'Authorization': 'Bearer ${_prefs!.getString('access_token')}',
        if (headers != null) ...headers,
      };

  Map<String, String> _withAuthHeaders(Map<String, String>? headers) =>
      <String, String>{
        'Accept': 'application/json',
        if (_isNgrok) 'ngrok-skip-browser-warning': 'true',
        if (_prefs?.getString('access_token') != null)
          'Authorization': 'Bearer ${_prefs!.getString('access_token')}',
        if (headers != null) ...headers,
      };

  void _logRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[ApiService][$method] ${uri.toString()}');
    if (headers != null && headers.isNotEmpty) {
      final Map<String, String> safeHeaders = Map<String, String>.from(headers);
      if (safeHeaders.containsKey('Authorization')) {
        final String auth = safeHeaders['Authorization']!;
        final String masked =
            auth.length > 16
                ? '${auth.substring(0, 16)}...' // avoid logging full token
                : auth;
        safeHeaders['Authorization'] = masked;
      }
      debugPrint('Headers: ${safeHeaders.toString()}');
    }
    if (body != null && body.isNotEmpty) {
      debugPrint('Body: ${jsonEncode(body)}');
    }
  }

  void _logResponse(http.Response response) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      '[ApiService][Response] '
      'Status: ${response.statusCode} Body: ${response.body}',
    );
    if (response.statusCode >= 300 && response.statusCode < 400) {
      final String? loc = response.headers['location'];
      if (loc != null && loc.isNotEmpty) {
        debugPrint('[ApiService][Redirect] -> $loc');
      }
    }
  }
}
