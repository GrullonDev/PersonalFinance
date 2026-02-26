import 'package:personal_finance/core/data/datasources/base_firestore_service.dart';
import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/features/budgets/data/models/budget_model.dart';

abstract class BudgetRemoteDataSource {
  Future<List<BudgetModel>> getBudgets();
  Future<BudgetModel> createBudget(BudgetModel budget);
  Future<BudgetModel> updateBudget(String id, BudgetModel budget);
  Future<void> deleteBudget(String id);
}

class BudgetRemoteDataSourceImpl extends BaseFirestoreService<BudgetModel>
    implements BudgetRemoteDataSource {
  @override
  String get collectionName => 'budgets';

  @override
  BudgetModel fromFirestore(Map<String, dynamic> json) =>
      BudgetModel.fromFirestore(json);

  @override
  Future<List<BudgetModel>> getBudgets() async {
    try {
      return await getAll();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    try {
      await upsert(budget);
      return budget;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<BudgetModel> updateBudget(String id, BudgetModel budget) async {
    try {
      await upsert(budget);
      return budget;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await softDelete(id);
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }
}
