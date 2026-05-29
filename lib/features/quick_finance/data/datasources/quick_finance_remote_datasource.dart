import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';
import 'package:personal_finance/features/quick_finance/data/models/sync_operation_model.dart';

/// Contrato para el datasource remoto de Quick Finance.
///
/// Todas las colecciones se organizan por usuario:
///   `users/{userId}/transactions/{transactionId}`
abstract class QuickFinanceRemoteDataSource {
  /// Envía las transacciones pendientes al servidor (push).
  /// Aplica las [operations] sobre los [transactions] correspondientes.
  /// Devuelve el conjunto de IDs de operaciones que se subieron con éxito.
  /// Las operaciones que fallen individualmente se registran pero no bloquean
  /// el resto del batch.
  Future<Set<String>> pushPendingOperations({
    required String userId,
    required List<SyncOperationModel> operations,
    required List<TransactionModel> transactions,
  });

  /// Descarga transacciones del usuario desde Firestore.
  ///
  /// - [updatedAfter] `null` → descarga completa (bootstrap / primer sync).
  /// - [updatedAfter] fecha → solo documentos con `updatedAt > updatedAfter`
  ///   (delta sync para sincronizaciones posteriores).
  Future<List<TransactionModel>> fetchTransactions(
    String userId, {
    DateTime? updatedAfter,
  });
}
