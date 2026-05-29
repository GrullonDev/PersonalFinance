import 'package:flutter/foundation.dart';
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
///   1. [watchTransactions] y [watchBalance] suscriben el stream de Hive
///      inmediatamente — la UI responde sin esperar la red.
///   2. Si no hay datos en caché para el usuario, se dispara un fetch remoto
///      en segundo plano; el resultado se upserta en Hive y el stream lo
///      propaga automáticamente a la UI.
///   3. El ID del usuario fluye explícito por todas las capas: nunca se mezclan
///      datos de usuarios distintos aunque compartan el mismo dispositivo.
///   4. Toda mutación escribe primero en Hive y encola una SyncOperation para
///      que el SyncManager la envíe a Firestore.
class QuickFinanceRepositoryImpl implements QuickFinanceRepository {
  final QuickFinanceLocalDataSource localDataSource;
  final QuickFinanceRemoteDataSource remoteDataSource;

  /// Guarda los userId con fetch en curso para no lanzar peticiones duplicadas.
  final _fetchingUsers = <String>{};

  QuickFinanceRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  // ---------------------------------------------------------------------------
  // Streams — Local-First
  // ---------------------------------------------------------------------------

  @override
  Stream<List<TransactionEntity>> watchTransactions({required String userId}) {
    // 1. Dispara fetch remoto en segundo plano si Hive está vacío para este
    //    usuario. El upsert escribe en Hive y el stream lo propaga solo.
    _fetchIfNotCached(userId);

    // 2. Devuelve el stream local inmediatamente — sin bloquear en red.
    return localDataSource
        .watchTransactions(userId)
        .map((models) => models.cast<TransactionEntity>());
  }

  @override
  Stream<BalanceSummaryEntity> watchBalance({required String userId}) =>
      localDataSource.watchTransactions(userId).map((transactions) {
        double income = 0;
        double expenses = 0;
        for (final t in transactions) {
          // watchTransactions(userId) ya filtra soft-deleted y por userId
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

  /// Fetch remoto de seguridad: solo se ejecuta si Hive no tiene datos para
  /// [userId] y no hay ya un fetch en curso para ese usuario.
  /// El SyncManager sigue siendo responsable del sync periódico y del push.
  Future<void> _fetchIfNotCached(String userId) async {
    if (_fetchingUsers.contains(userId)) return;

    final hasCached = await localDataSource.hasCachedTransactions(userId);
    if (hasCached) return;

    _fetchingUsers.add(userId);
    try {
      final remote = await remoteDataSource.fetchTransactions(userId);
      if (remote.isNotEmpty) {
        await localDataSource.upsertTransactions(
          remote.map((t) => t.copyWith(syncStatus: SyncStatus.synced)).toList(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('QuickFinanceRepository background fetch failed: $e');
      }
    } finally {
      _fetchingUsers.remove(userId);
    }
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
    // Soft-delete: marcar con deletedAt.
    // getAllTransactions incluye soft-deleted ya existentes, evitando error si
    // la transacción fue borrada en otro dispositivo antes de hacer sync.
    final transaction = await localDataSource.getTransaction(id);
    if (transaction == null) return; // ya eliminada o id inválido

    final updatedModel = TransactionModel.fromEntity(transaction).copyWith(
      deletedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );

    await localDataSource.saveTransaction(updatedModel);
    await _createSyncOp(id, SyncAction.delete);
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(
      transaction,
    ).copyWith(syncStatus: SyncStatus.pending, updatedAt: DateTime.now());
    await localDataSource.saveTransaction(model);
    await _createSyncOp(model.id, SyncAction.update);
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
