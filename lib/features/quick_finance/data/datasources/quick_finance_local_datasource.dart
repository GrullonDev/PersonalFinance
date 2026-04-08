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
