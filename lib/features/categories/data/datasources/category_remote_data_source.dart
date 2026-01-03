import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  CategoryRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw ApiException(message: 'User not authenticated', statusCode: 401);
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('users').doc(_uid).collection('categories');

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _categoriesCollection.get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      final docRef = _categoriesCollection.doc();
      final data = category.toJson()..remove('id'); // Firestore generates ID
      await docRef.set(data);
      return CategoryModel.fromJson({...data, 'id': docRef.id});
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
      final data = category.toJson()..remove('id');
      await _categoriesCollection.doc(categoryId).update(data);
      return category;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoriesCollection.doc(categoryId).delete();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }
}
