import '../models/transaction_model.dart';
import '../models/sync_operation_model.dart';

/// Contrato de acceso al almacenamiento local (Hive).
///
/// ## Convención activo / total
///
/// - [watchTransactions] y [getTransactions] devuelven **solo transacciones
///   activas** (sin `deletedAt`). Son las fuentes para la UI y el balance.
///
/// - [getAllTransactions] devuelve **todas**, incluyendo soft-deleted.
///   Úsalo en la fase de push del [SyncManager] para localizar cuerpos de
///   transacciones que aún no se han sincronizado con Firestore.
abstract class QuickFinanceLocalDataSource {
  // ── Transacciones ──────────────────────────────────────────────────────────

  /// Persiste o reemplaza una transacción por su `id`.
  Future<void> saveTransaction(TransactionModel transaction);

  /// Persiste o reemplaza un lote de transacciones.
  Future<void> saveTransactions(List<TransactionModel> transactions);

  /// Stream de transacciones **activas** (deletedAt == null),
  /// ordenadas por `createdAt` descendente.
  /// Emite el estado actual al suscribirse y ante cada cambio en el box.
  Stream<List<TransactionModel>> watchTransactions();

  /// Snapshot de transacciones **activas** (deletedAt == null),
  /// ordenadas por `createdAt` descendente.
  Future<List<TransactionModel>> getTransactions();

  /// Snapshot de **todas** las transacciones, incluyendo soft-deleted.
  /// Necesario durante el push de sync para encontrar cuerpos de operaciones.
  Future<List<TransactionModel>> getAllTransactions();

  /// Devuelve una transacción por `id`, o `null` si no existe.
  Future<TransactionModel?> getTransaction(String id);

  /// Elimina físicamente una transacción del box local (purge post-sync).
  Future<void> deleteTransaction(String id);

  // ── Cola de sincronización ────────────────────────────────────────────────

  /// Encola una nueva operación de sincronización.
  Future<void> saveSyncOperation(SyncOperationModel operation);

  /// Devuelve todas las operaciones con `processed == false`.
  Future<List<SyncOperationModel>> getPendingSyncOperations();

  /// Marca una operación como procesada (processed = true).
  Future<void> markSyncOperationAsProcessed(String id);

  /// Elimina físicamente todas las operaciones ya procesadas del box.
  /// Llámalo al finalizar un ciclo de sync exitoso para evitar crecimiento.
  Future<void> deleteProcessedSyncOperations();
}
