import 'package:personal_finance/core/data/datasources/base_firestore_service.dart';
import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/features/debts/data/models/debt_model.dart';

abstract class DebtRemoteDataSource {
  Future<List<DebtModel>> getDebts();
  Future<DebtModel> createDebt(DebtModel debt);
  Future<DebtModel> updateDebt(String id, DebtModel debt);
  Future<void> deleteDebt(String id);
}

class DebtRemoteDataSourceImpl extends BaseFirestoreService<DebtModel>
    implements DebtRemoteDataSource {
  @override
  String get collectionName => 'debts';

  @override
  DebtModel fromFirestore(Map<String, dynamic> json) =>
      DebtModel.fromFirestore(json);

  @override
  Future<List<DebtModel>> getDebts() async {
    try {
      return await getAll();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<DebtModel> createDebt(DebtModel debt) async {
    try {
      await upsert(debt);
      return debt;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<DebtModel> updateDebt(String id, DebtModel debt) async {
    try {
      await upsert(debt);
      return debt;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteDebt(String id) async {
    try {
      await softDelete(id);
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }
}
