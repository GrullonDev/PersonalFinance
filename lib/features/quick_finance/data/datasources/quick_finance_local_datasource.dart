import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/sync_operation_model.dart';

abstract class QuickFinanceLocalDataSource {
  Future<void> saveTransaction(TransactionModel transaction);
  Future<void> saveTransactions(List<TransactionModel> transactions);
  Stream<List<TransactionModel>> watchTransactions();
  Future<List<TransactionModel>> getTransactions();
  Future<void> deleteTransaction(String id);
  
  Future<void> saveSyncOperation(SyncOperationModel operation);
  Future<List<SyncOperationModel>> getPendingSyncOperations();
  Future<void> markSyncOperationAsProcessed(String id);
}

class QuickFinanceLocalDataSourceImpl implements QuickFinanceLocalDataSource {
  final Box<TransactionModel> transactionBox;
  final Box<SyncOperationModel> syncOperationBox;

  QuickFinanceLocalDataSourceImpl({
    required this.transactionBox,
    required this.syncOperationBox,
  });

  @override
  Future<void> saveTransaction(TransactionModel transaction) async {
    await transactionBox.put(transaction.id, transaction);
  }

  @override
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final entries = {for (var t in transactions) t.id: t};
    await transactionBox.putAll(entries);
  }

  @override
  Stream<List<TransactionModel>> watchTransactions() {
    return transactionBox.watch().map((_) => transactionBox.values.toList());
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    return transactionBox.values.toList();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await transactionBox.delete(id);
  }

  @override
  Future<void> saveSyncOperation(SyncOperationModel operation) async {
    await syncOperationBox.put(operation.id, operation);
  }

  @override
  Future<List<SyncOperationModel>> getPendingSyncOperations() async {
    return syncOperationBox.values.where((op) => !op.processed).toList();
  }

  @override
  Future<void> markSyncOperationAsProcessed(String id) async {
    final op = syncOperationBox.get(id);
    if (op != null) {
      await syncOperationBox.put(id, SyncOperationModel(
        id: op.id,
        transactionId: op.transactionId,
        action: op.action,
        createdAt: op.createdAt,
        processed: true,
      ));
    }
  }
}
