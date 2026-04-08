import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../models/sync_operation_model.dart';
import 'quick_finance_remote_datasource.dart';

class QuickFinanceRemoteDataSourceImpl implements QuickFinanceRemoteDataSource {
  final FirebaseFirestore firestore;

  QuickFinanceRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> pushTransactions(List<TransactionModel> transactions) async {
    final batch = firestore.batch();
    for (final t in transactions) {
      final docRef = firestore.collection('transactions').doc(t.id);
      batch.set(docRef, t.toJson());
    }
    await batch.commit();
  }

  @override
  Future<List<TransactionModel>> pullTransactions(DateTime lastSync) async {
    final snapshot = await firestore
        .collection('transactions')
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSync))
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<void> syncSyncOperations(List<SyncOperationModel> operations) async {
    // TODO: implement remote sync operation resolution
  }
}
