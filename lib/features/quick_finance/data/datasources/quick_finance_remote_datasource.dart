import '../models/transaction_model.dart';
import '../models/sync_operation_model.dart';

abstract class QuickFinanceRemoteDataSource {
  Future<void> pushTransactions(List<TransactionModel> transactions);
  Future<List<TransactionModel>> pullTransactions(DateTime lastSync);
  Future<void> syncSyncOperations(List<SyncOperationModel> operations);
}
