import 'package:personal_finance/core/data/datasources/base_firestore_service.dart';
import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/features/categories/data/models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> createCategory(CategoryModel category);
  Future<CategoryModel> updateCategory(
    String categoryId,
    CategoryModel category,
  );
  Future<void> deleteCategory(String categoryId);
}

class CategoryRemoteDataSourceImpl extends BaseFirestoreService<CategoryModel>
    implements CategoryRemoteDataSource {
  @override
  String get collectionName => 'categories';

  @override
  CategoryModel fromFirestore(Map<String, dynamic> json) =>
      CategoryModel.fromFirestore(json);

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      return await getAll();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      await upsert(category);
      return category;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<CategoryModel> updateCategory(
    String categoryId,
    CategoryModel category,
  ) async {
    try {
      await upsert(category);
      return category;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      await softDelete(categoryId);
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }
}
