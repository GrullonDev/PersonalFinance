import 'package:hive/hive.dart';
import '../models/transaction_model.dart';
import '../models/sync_operation_model.dart';
import 'quick_finance_local_datasource.dart';

class QuickFinanceLocalDataSourceImpl implements QuickFinanceLocalDataSource {
  final Box<TransactionModel> transactionBox;
  final Box<SyncOperationModel> syncOperationBox;

  QuickFinanceLocalDataSourceImpl({
    required this.transactionBox,
    required this.syncOperationBox,
  });

  // ── Transacciones ──────────────────────────────────────────────────────────

  @override
  Future<void> saveTransaction(TransactionModel transaction) async {
    await transactionBox.put(transaction.id, transaction);
  }

  @override
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final entries = {for (final t in transactions) t.id: t};
    await transactionBox.putAll(entries);
  }

  @override
  Stream<List<TransactionModel>> watchTransactions() async* {
    // Emite inmediatamente el estado actual para que la UI no quede en blanco
    yield _activeTransactions();
    await for (final _ in transactionBox.watch()) {
      yield _activeTransactions();
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    return _activeTransactions();
  }

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    // Incluye soft-deleted; necesario para el pipeline de sync push
    return _sortedByDateDesc(transactionBox.values.toList());
  }

  @override
  Future<TransactionModel?> getTransaction(String id) async {
    return transactionBox.get(id);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await transactionBox.delete(id);
  }

  // ── Cola de sincronización ────────────────────────────────────────────────

  @override
  Future<void> saveSyncOperation(SyncOperationModel operation) async {
    await syncOperationBox.put(operation.id, operation);
  }

  @override
  Future<List<SyncOperationModel>> getPendingSyncOperations() async {
    // Orden FIFO: las más antiguas se procesan primero
    final pending = syncOperationBox.values
        .where((op) => !op.processed)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return pending;
  }

  @override
  Future<void> markSyncOperationAsProcessed(String id) async {
    final op = syncOperationBox.get(id);
    if (op == null) return; // operación ya eliminada o nunca existió
    await syncOperationBox.put(id, op.copyWith(processed: true));
  }

  @override
  Future<void> deleteProcessedSyncOperations() async {
    final processedKeys = syncOperationBox.values
        .where((op) => op.processed)
        .map((op) => op.id)
        .toList();
    await syncOperationBox.deleteAll(processedKeys);
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  /// Transacciones activas (sin soft-delete) ordenadas por createdAt desc.
  List<TransactionModel> _activeTransactions() {
    final active = transactionBox.values
        .where((t) => t.deletedAt == null)
        .toList();
    return _sortedByDateDesc(active);
  }

  /// Ordena una lista de transacciones por `createdAt` descendente (más
  /// reciente primero). Devuelve una nueva lista; no muta la original.
  List<TransactionModel> _sortedByDateDesc(List<TransactionModel> list) {
    return List<TransactionModel>.from(list)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
