import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_local_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_remote_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/models/sync_operation_model.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/balance_summary_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/repositories/quick_finance_repository.dart';

class QuickFinanceRepositoryImpl implements QuickFinanceRepository {
  final QuickFinanceLocalDataSource localDataSource;
  final QuickFinanceRemoteDataSource remoteDataSource;

  QuickFinanceRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    // UI reads from Hive
    return localDataSource.watchTransactions();
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    
    // 1. UI always reads from Local Source - Status Pending
    await localDataSource.saveTransaction(model);
    
    // 2. Create sync operation
    final syncOp = SyncOperationModel(
      id: 'op_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: model.id,
      action: SyncAction.create,
      createdAt: DateTime.now(),
      processed: false,
    );
    await localDataSource.saveSyncOperation(syncOp);
    
    // 3. Try immediate push if possible
    _tryImmediatePush(model, syncOp.id);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    // Soft delete: UI reads from Hive and we'll filter out records with deletedAt != null
    final transactions = await localDataSource.getTransactions();
    final transaction = transactions.firstWhere((t) => t.id == id);
    
    final updatedModel = transaction.copyWith(
      deletedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );
    
    await localDataSource.saveTransaction(updatedModel);
    
    final syncOp = SyncOperationModel(
      id: 'op_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: id,
      action: SyncAction.delete,
      createdAt: DateTime.now(),
      processed: false,
    );
    await localDataSource.saveSyncOperation(syncOp);
    
    _tryImmediatePush(updatedModel, syncOp.id);
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction).copyWith(
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );
    await localDataSource.saveTransaction(model);
    
    final syncOp = SyncOperationModel(
      id: 'op_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: model.id,
      action: SyncAction.update,
      createdAt: DateTime.now(),
      processed: false,
    );
    await localDataSource.saveSyncOperation(syncOp);
    
    _tryImmediatePush(model, syncOp.id);
  }

  void _tryImmediatePush(TransactionModel model, String opId) async {
    try {
      // In a real implementation we'd check connectivity_plus here
      await remoteDataSource.pushTransactions([model]);
      
      // If success, update local status
      final syncedModel = model.copyWith(syncStatus: SyncStatus.synced);
      await localDataSource.saveTransaction(syncedModel);
      await localDataSource.markSyncOperationAsProcessed(opId);
    } catch (e) {
      // If fails, stays pending. Background sync will pick it up.
    }
  }

  @override
  Stream<BalanceSummaryEntity> watchBalance() {
    return localDataSource.watchTransactions().map((transactions) {
      double income = 0;
      double expenses = 0;
      
      for (var t in transactions) {
        if (t.deletedAt != null) continue;
        if (t.type == TransactionType.income) {
          income += t.amount;
        } else {
          expenses += t.amount;
        }
      }
      
      return BalanceSummaryEntity(
        totalBalance: income - expenses,
        totalIncome: income,
        totalExpenses: expenses,
      );
    });
  }

  @override
  Future<void> syncPendingTransactions() async {
    await _syncInBackground();
  }

  Future<void> _syncInBackground() async {
    try {
      final pendingOps = await localDataSource.getPendingSyncOperations();
      if (pendingOps.isEmpty) return;

      final transactions = await localDataSource.getTransactions();

      for (var op in pendingOps) {
        final transaction = transactions.firstWhere((t) => t.id == op.transactionId);
        
        // Push to remote
        await remoteDataSource.pushTransactions([transaction]);
        
        // Mark as synced
        final syncedModel = transaction.copyWith(syncStatus: SyncStatus.synced);
        await localDataSource.saveTransaction(syncedModel);
        await localDataSource.markSyncOperationAsProcessed(op.id);
      }
    } catch (e) {
      // Log or handle sync error
    }
  }
}
