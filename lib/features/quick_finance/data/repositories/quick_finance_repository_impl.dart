import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_local_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_remote_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/models/sync_operation_model.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/balance_summary_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/repositories/quick_finance_repository.dart';

/// Implementación del repositorio Quick Finance.
///
/// Estrategia Local-First:
///   - Toda mutación escribe primero en Hive (UI instantáneo).
///   - Crea una SyncOperation para que el SyncManager la envíe después.
///   - NO intenta push inmediato; eso lo hace el SyncManager.
class QuickFinanceRepositoryImpl implements QuickFinanceRepository {
  final QuickFinanceLocalDataSource localDataSource;
  final QuickFinanceRemoteDataSource remoteDataSource;

  QuickFinanceRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    // UI lee directo de Hive
    return localDataSource.watchTransactions().map(
      (models) => models.cast<TransactionEntity>().toList(),
    );
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);

    // 1. Guardar localmente (UI se actualiza instantáneamente)
    await localDataSource.saveTransaction(model);

    // 2. Crear operación de sync
    await _createSyncOp(model.id, SyncAction.create);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    // Soft-delete: marcar con deletedAt
    final transactions = await localDataSource.getTransactions();
    final transaction = transactions.firstWhere((t) => t.id == id);

    final updatedModel = transaction.copyWith(
      deletedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );

    await localDataSource.saveTransaction(updatedModel);
    await _createSyncOp(id, SyncAction.delete);
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction).copyWith(
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );
    await localDataSource.saveTransaction(model);
    await _createSyncOp(model.id, SyncAction.update);
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
    // Delegado al SyncManager. Este método se mantiene por compatibilidad
    // con el contrato del repositorio, pero no debería llamarse directamente.
    // El SyncManager usa los datasources directamente.
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _createSyncOp(String transactionId, SyncAction action) async {
    final syncOp = SyncOperationModel(
      id: 'op_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: transactionId,
      action: action,
      createdAt: DateTime.now(),
      processed: false,
    );
    await localDataSource.saveSyncOperation(syncOp);
  }
}
