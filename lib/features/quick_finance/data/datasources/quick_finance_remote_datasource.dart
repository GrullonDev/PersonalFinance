import '../models/transaction_model.dart';
import '../models/sync_operation_model.dart';

/// Contrato para el datasource remoto de Quick Finance.
///
/// Todas las colecciones se organizan por usuario:
///   `users/{userId}/transactions/{transactionId}`
abstract class QuickFinanceRemoteDataSource {
  /// Envía las transacciones pendientes al servidor (push).
  /// Aplica las [operations] sobre los [transactions] correspondientes.
  Future<void> pushPendingOperations({
    required String userId,
    required List<SyncOperationModel> operations,
    required List<TransactionModel> transactions,
  });

  /// Descarga las transacciones modificadas desde [lastSyncAt] (pull).
  /// Retorna solo las que se han actualizado después de esa fecha.
  Future<List<TransactionModel>> pullLatestTransactions({
    required String userId,
    required DateTime lastSyncAt,
  });
}
