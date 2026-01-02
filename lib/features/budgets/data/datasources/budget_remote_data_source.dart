import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/features/budgets/data/models/budget_model.dart';

abstract class BudgetRemoteDataSource {
  Future<List<BudgetModel>> getBudgets();
  Future<BudgetModel> createBudget(BudgetModel budget);
  Future<BudgetModel> updateBudget(String id, BudgetModel budget);
  Future<void> deleteBudget(String id);
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  BudgetRemoteDataSourceImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw ApiException(message: 'User not authenticated', statusCode: 401);
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _budgetsCollection =>
      _firestore.collection('users').doc(_uid).collection('budgets');

  @override
  Future<List<BudgetModel>> getBudgets() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _budgetsCollection.orderBy('fecha_inicio').get();
      return snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                BudgetModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    try {
      final DocumentReference<Map<String, dynamic>> docRef =
          _budgetsCollection.doc();
      final Map<String, dynamic> data = budget.toJson()..remove('id');
      await docRef.set(data);
      return BudgetModel.fromJson({...data, 'id': docRef.id});
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<BudgetModel> updateBudget(String id, BudgetModel budget) async {
    try {
      final Map<String, dynamic> data = budget.toJson()..remove('id');
      await _budgetsCollection.doc(id).update(data);
      return BudgetModel.fromJson({...data, 'id': id});
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await _budgetsCollection.doc(id).delete();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }
}
