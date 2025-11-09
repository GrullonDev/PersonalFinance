import 'dart:convert';

import 'package:http/http.dart' show Response;

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/network/api_service.dart';
import 'package:personal_finance/features/categories/data/models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> createCategory(CategoryModel category);
  Future<CategoryModel> updateCategory(int categoryId, CategoryModel category);
  Future<void> deleteCategory(int categoryId);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  CategoryRemoteDataSourceImpl(this._apiService);

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

  @override
  Future<List<CategoryModel>> getCategories() async {
    final Response response = await _apiService.get('/api/v1/categories');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic decoded =
          response.body.isEmpty ? <dynamic>[] : jsonDecode(response.body);
      final List<Map<String, dynamic>> list = _extractList(decoded);
      return list.map(CategoryModel.fromJson).toList();
    }
    throw ApiException(
      message: 'Error al cargar categorías',
      statusCode: response.statusCode,
    );
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    final Response response = await _apiService.post(
      '/api/v1/categories',
      body:
          category.toJson()
            ..remove('id')
            ..remove('profile_id'),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final dynamic decoded =
          response.body.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(response.body);
      final Map<String, dynamic> map = _extractMap(decoded);
      return CategoryModel.fromJson(map);
    }
    throw ApiException(
      message: _extractDetailMessage(response.body),
      statusCode: response.statusCode,
    );
  }

  @override
  Future<CategoryModel> updateCategory(
    int categoryId,
    CategoryModel category,
  ) async {
    final Response response = await _apiService.put(
      '/api/v1/categories/$categoryId',
      body: <String, dynamic>{'nombre': category.nombre, 'tipo': category.tipo},
    );
    if (response.statusCode == 200) {
      final dynamic decoded =
          response.body.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(response.body);
      final Map<String, dynamic> map = _extractMap(decoded);
      return CategoryModel.fromJson(map);
    }
    throw ApiException(
      message: _extractDetailMessage(response.body),
      statusCode: response.statusCode,
    );
  }

  @override
  Future<void> deleteCategory(int categoryId) async {
    final Response response = await _apiService.delete(
      '/api/v1/categories/$categoryId',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw ApiException(
      message: _extractDetailMessage(
        response.body.isEmpty ? '{}' : response.body,
      ),
      statusCode: response.statusCode,
    );
  }

  String _extractDetailMessage(String body) {
    try {
      final dynamic decoded = body.isNotEmpty ? jsonDecode(body) : null;
      if (decoded is Map<String, dynamic>) {
        final dynamic detail = decoded['detail'];
        if (detail is String) return detail;
        if (detail is List) {
          return detail
              .whereType<Map<String, dynamic>>()
              .map((Map<String, dynamic> e) => e['msg']?.toString() ?? '')
              .where((String e) => e.isNotEmpty)
              .join('\n');
        }
      }
    } catch (_) {}
    return 'Error desconocido en solicitud de categorías';
  }
}
