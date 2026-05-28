import 'package:personal_finance/core/data/datasources/base_firestore_service.dart';
import 'package:personal_finance/features/transactions/data/models/transaction_model.dart';

class TransactionFirestoreService
    extends BaseFirestoreService<TransactionModel> {
  @override
  String get collectionName => 'transactions';

  @override
  TransactionModel fromFirestore(Map<String, dynamic> json) =>
      TransactionModel.fromFirestore(json);
}
