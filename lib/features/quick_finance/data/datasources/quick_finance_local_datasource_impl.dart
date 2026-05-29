import 'dart:async';

import 'package:hive/hive.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';
import 'package:personal_finance/features/quick_finance/data/models/sync_operation_model.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_local_datasource.dart';

class QuickFinanceLocalDataSourceImpl implements QuickFinanceLocalDataSource {
  final Box<TransactionModel> transactionBox;
  final Box<SyncOperationModel> syncOperationBox;

  /// Usuario activo. Cuando es null, los métodos de lectura devuelven vacío
  /// para evitar mostrar datos de otro usuario antes de que el auth resuelva.
  String? _userId;

  // _userIdChanged eliminado: watchTransactions(userId) recibe el userId
  // directamente, por lo que no necesita señal de refresco externa.

  QuickFinanceLocalDataSourceImpl({
    required this.transactionBox,
    required this.syncOperationBox,
  });

  // ── Identidad ─────────────────────────────────────────────────────────────

  @override
  void setUserId(String userId) {
    _userId = userId;
    // Ya no emite señal: watchTransactions(userId) recibe userId explícito.
  }

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
  Future<void> upsertTransactions(List<TransactionModel> transactions) =>
      saveTransactions(transactions);

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    // El stream es creado con el userId fijo: nunca puede mezclar usuarios,
    // incluso si setUserId cambia después de la suscripción.
    final controller = StreamController<List<TransactionModel>>();

    controller.add(_activeTransactionsFor(userId));

    final boxSub = transactionBox.watch().listen(
      (_) => controller.add(_activeTransactionsFor(userId)),
    );

    controller.onCancel = () {
      boxSub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<bool> hasCachedTransactions(String userId) async => transactionBox
      .values
      .any((t) => t.userId == userId && t.deletedAt == null);

  @override
  Future<List<TransactionModel>> getTransactions() async =>
      _activeTransactions();

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    // Incluye soft-deleted; necesario para el pipeline de sync push.
    // Filtra por userId para que el push no envíe datos de otro usuario.
    final uid = _userId;
    final all =
        uid == null
            ? <TransactionModel>[]
            : transactionBox.values.where((t) => t.userId == uid).toList();
    return _sortedByDateDesc(all);
  }

  @override
  Future<TransactionModel?> getTransaction(String id) async =>
      transactionBox.get(id);

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
    final pending =
        syncOperationBox.values.where((op) => !op.processed).toList()
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
    final processedKeys =
        syncOperationBox.values
            .where((op) => op.processed)
            .map((op) => op.id)
            .toList();
    await syncOperationBox.deleteAll(processedKeys);
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  /// Transacciones activas del [userId] explícito (sin soft-delete),
  /// ordenadas por createdAt desc. Usado por [watchTransactions].
  List<TransactionModel> _activeTransactionsFor(String userId) =>
      _sortedByDateDesc(
        transactionBox.values
            .where((t) => t.deletedAt == null && t.userId == userId)
            .toList(),
      );

  /// Igual que [_activeTransactionsFor] pero usa [_userId] interno.
  /// Solo para métodos legacy que dependen de [setUserId] (getTransactions).
  List<TransactionModel> _activeTransactions() {
    final uid = _userId;
    if (uid == null) return [];
    return _activeTransactionsFor(uid);
  }

  /// Ordena una lista de transacciones por `createdAt` descendente (más
  /// reciente primero). Devuelve una nueva lista; no muta la original.
  List<TransactionModel> _sortedByDateDesc(List<TransactionModel> list) =>
      List<TransactionModel>.from(list)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
