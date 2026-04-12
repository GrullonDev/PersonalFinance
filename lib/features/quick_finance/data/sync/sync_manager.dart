import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_local_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_remote_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estado de sincronización expuesto por el [SyncManager].
enum SyncState { idle, syncing, success, error }

/// Resultado de una operación de sync.
class SyncResult {
  final SyncState state;
  final int pushedCount;
  final int pulledCount;
  final String? errorMessage;

  const SyncResult({
    required this.state,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.errorMessage,
  });

  const SyncResult.idle()
      : state = SyncState.idle,
        pushedCount = 0,
        pulledCount = 0,
        errorMessage = null;
}

/// Gestiona la sincronización bidireccional entre Hive y Firestore.
///
/// Se dispara en 3 escenarios:
///   1. Al abrir la app ([syncOnAppStart])
///   2. Al recuperar internet ([startConnectivityListener])
///   3. Manual — pull-to-refresh o botón ([syncNow])
class SyncManager {
  final QuickFinanceLocalDataSource _localDataSource;
  final QuickFinanceRemoteDataSource _remoteDataSource;
  final Connectivity _connectivity;

  /// Key usada en SharedPreferences para guardar la última fecha de sync.
  static const _lastSyncKey = 'quick_finance_last_sync_at';

  /// Stream controller para exponer el estado de sync a la UI.
  final _stateController = StreamController<SyncResult>.broadcast();
  Stream<SyncResult> get syncStream => _stateController.stream;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// ID del usuario actual. Se debe asignar antes de sincronizar.
  String? _userId;

  /// Flag para evitar syncs concurrentes.
  bool _isSyncing = false;

  SyncManager({
    required QuickFinanceLocalDataSource localDataSource,
    required QuickFinanceRemoteDataSource remoteDataSource,
    Connectivity? connectivity,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _connectivity = connectivity ?? Connectivity();

  /// Configura el userId. Debe llamarse antes de cualquier sync.
  void setUserId(String userId) {
    _userId = userId;
  }

  // ---------------------------------------------------------------------------
  // Trigger 1: Al abrir la app
  // ---------------------------------------------------------------------------

  /// Intenta sincronizar al arrancar la aplicación.
  /// Si no hay conexión, falla silenciosamente.
  Future<void> syncOnAppStart() async => syncNow();

  // ---------------------------------------------------------------------------
  // Trigger 2: Al recuperar conectividad
  // ---------------------------------------------------------------------------

  /// Inicia un listener de conectividad. Cuando se detecta que el
  /// dispositivo recupera la conexión, dispara un sync automático.
  void startConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) {
        if (result != ConnectivityResult.none) {
          syncNow();
        }
      },
    );
  }

  /// Detiene el listener de conectividad.
  void stopConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  // ---------------------------------------------------------------------------
  // Trigger 3: Manual (pull-to-refresh / botón)
  // ---------------------------------------------------------------------------

  /// Ejecuta un ciclo de sincronización completo:
  ///   1. Push: envía operaciones pendientes locales al servidor.
  ///   2. Pull: descarga cambios remotos desde el último sync.
  ///
  /// Protegido contra ejecuciones concurrentes.
  Future<SyncResult> syncNow() async {
    if (_isSyncing) return const SyncResult.idle();
    if (_userId == null) {
      debugPrint('SyncManager: userId no configurado, saltando sync.');
      return const SyncResult.idle();
    }

    _isSyncing = true;
    _stateController.add(const SyncResult(state: SyncState.syncing));

    try {
      // --- PUSH ---
      final pushedCount = await _push();

      // --- PULL ---
      final pulledCount = await _pull();

      // Purgar operaciones procesadas para evitar crecimiento ilimitado del box
      await _localDataSource.deleteProcessedSyncOperations();

      // Guardar timestamp del sync exitoso
      await _saveLastSyncTimestamp();

      final result = SyncResult(
        state: SyncState.success,
        pushedCount: pushedCount,
        pulledCount: pulledCount,
      );
      _stateController.add(result);
      return result;
    } catch (e) {
      debugPrint('SyncManager error: $e');
      final result = SyncResult(
        state: SyncState.error,
        errorMessage: e.toString(),
      );
      _stateController.add(result);
      return result;
    } finally {
      _isSyncing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Push — enviar pendientes
  // ---------------------------------------------------------------------------

  Future<int> _push() async {
    final pendingOps = await _localDataSource.getPendingSyncOperations();
    if (pendingOps.isEmpty) return 0;

    // getAllTransactions incluye soft-deleted para que los DELETE ops puedan
    // actualizar el syncStatus antes de que la transacción sea purgada
    final allTransactions = await _localDataSource.getAllTransactions();

    await _remoteDataSource.pushPendingOperations(
      userId: _userId!,
      operations: pendingOps,
      transactions: allTransactions,
    );

    // Marcar operaciones como procesadas y transacciones como synced
    for (final op in pendingOps) {
      await _localDataSource.markSyncOperationAsProcessed(op.id);

      // Actualizar syncStatus de la transacción a synced
      try {
        final tx = allTransactions.firstWhere(
          (t) => t.id == op.transactionId,
        );
        final syncedTx = tx.copyWith(syncStatus: SyncStatus.synced);
        await _localDataSource.saveTransaction(syncedTx);
      } catch (_) {
        // Transacción no encontrada localmente (posible delete físico)
      }
    }

    return pendingOps.length;
  }

  // ---------------------------------------------------------------------------
  // Pull — descargar novedades
  // ---------------------------------------------------------------------------

  Future<int> _pull() async {
    final lastSync = await _getLastSyncTimestamp();

    final remoteTransactions = await _remoteDataSource.pullLatestTransactions(
      userId: _userId!,
      lastSyncAt: lastSync,
    );

    if (remoteTransactions.isEmpty) return 0;

    // Merge: las transacciones remotas sobrescriben las locales
    // (servidor gana en caso de conflicto simple)
    final mergedTransactions = <TransactionModel>[];
    for (final remote in remoteTransactions) {
      mergedTransactions.add(remote.copyWith(syncStatus: SyncStatus.synced));
    }

    await _localDataSource.saveTransactions(mergedTransactions);

    return remoteTransactions.length;
  }

  // ---------------------------------------------------------------------------
  // Timestamp helpers
  // ---------------------------------------------------------------------------

  Future<DateTime> _getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_lastSyncKey);
    if (stored != null) {
      return DateTime.tryParse(stored) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _saveLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  void dispose() {
    stopConnectivityListener();
    _stateController.close();
  }
}
