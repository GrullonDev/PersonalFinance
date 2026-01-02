import 'package:http/http.dart' as http;

// MOCK API SERVICE
// This file is a temporary stub to allow compilation while migrating to Firebase.
// The actual ApiService has been deleted.

class ApiService {
  ApiService();

  Future<http.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    throw UnimplementedError(
      "Backend integration has been removed. Migrate feature '$path' to Firebase.",
    );
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    throw UnimplementedError(
      "Backend integration has been removed. Migrate feature '$path' to Firebase.",
    );
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    throw UnimplementedError(
      "Backend integration has been removed. Migrate feature '$path' to Firebase.",
    );
  }

  Future<http.Response> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    throw UnimplementedError(
      "Backend integration has been removed. Migrate feature '$path' to Firebase.",
    );
  }
}
