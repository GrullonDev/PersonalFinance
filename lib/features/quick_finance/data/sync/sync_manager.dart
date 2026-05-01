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

  /// Clave SharedPreferences por usuario. Cada UID tiene su propio cursor de
  /// sync — evita que el delta pull de un usuario use la fecha de otro.
  static String _lastSyncKey(String userId) =>
      'quick_finance_last_sync_at_$userId';

  /// Stream controller para exponer el estado de sync a la UI.
  final _stateController = StreamController<SyncResult>.broadcast();
  Stream<SyncResult> get syncStream => _stateController.stream;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// ID del usuario actual. Se debe asignar antes de sincronizar.
  String? _userId;

  /// Flag para evitar syncs concurrentes.
  bool _isSyncing = false;

  /// Último estado de conectividad conocido. Null = desconocido (primer evento).
  bool? _wasConnected;

  SyncManager({
    required QuickFinanceLocalDataSource localDataSource,
    required QuickFinanceRemoteDataSource remoteDataSource,
    Connectivity? connectivity,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _connectivity = connectivity ?? Connectivity();

  /// Configura el userId en el SyncManager y en el datasource local.
  /// Debe llamarse antes de cualquier sync (típicamente al resolver el auth).
  void setUserId(String userId) {
    _userId = userId;
    _localDataSource.setUserId(userId);
  }

  // ---------------------------------------------------------------------------
  // Trigger 1: Al abrir la app
  // ---------------------------------------------------------------------------

  /// Descarga todas las transacciones del usuario desde Firestore y las
  /// persiste en Hive. Operación idempotente: si ya se ejecutó para este
  /// usuario (flag por UID en SharedPreferences), retorna inmediatamente.
  ///
  /// Llamar esto al resolver el auth garantiza que Hive esté poblado antes
  /// de que el usuario vea la pantalla principal.
  Future<SyncResult> hydrateCurrentUserTransactions() async {
    if (_isSyncing) return const SyncResult.idle();
    if (_userId == null) {
      debugPrint('SyncManager: userId no configurado, saltando hydration.');
      return const SyncResult.idle();
    }

    _isSyncing = true;
    _stateController.add(const SyncResult(state: SyncState.syncing));

    try {
      final count = await _hydrateIfNeeded();
      final result = SyncResult(state: SyncState.success, pulledCount: count);
      _stateController.add(result);
      return result;
    } catch (e) {
      debugPrint('SyncManager hydration error: $e');
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

  /// Intenta sincronizar al arrancar la aplicación:
  ///   1. Hydration — descarga todo si es la primera vez para este usuario.
  ///   2. Sync normal — push pendientes + pull delta.
  Future<void> syncOnAppStart() async {
    await hydrateCurrentUserTransactions();
    await syncNow();
  }

  // ---------------------------------------------------------------------------
  // Trigger 2: Al recuperar conectividad
  // ---------------------------------------------------------------------------

  /// Inicia un listener de conectividad. Dispara sync únicamente cuando el
  /// dispositivo recupera internet (transición offline → online), evitando
  /// intentos innecesarios de sync mientras no hay conexión.
  void startConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final isConnected = result != ConnectivityResult.none;
        // Solo sincronizar en la transición offline → online.
        if (isConnected && _wasConnected == false) {
          syncNow();
        }
        _wasConnected = isConnected;
      },
    );
  }

  /// Detiene el listener de conectividad.
  void stopConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _wasConnected = null;
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
      // Push y pull son independientes: el fallo de uno no bloquea al otro.
      // Si Firestore no está disponible, los datos locales siguen visibles.

      int pushedCount = 0;
      String? pushError;
      try {
        pushedCount = await _push();
      } catch (e) {
        pushError = e.toString();
        debugPrint('SyncManager push error (local data unaffected): $e');
      }

      int pulledCount = 0;
      String? pullError;
      try {
        pulledCount = await _pull();
      } catch (e) {
        pullError = e.toString();
        debugPrint('SyncManager pull error (local data unaffected): $e');
      }

      // Limpieza y cursor: solo si al menos una operación tuvo éxito.
      if (pushError == null && pushedCount > 0) {
        await _localDataSource.deleteProcessedSyncOperations();
      }
      if (pullError == null) {
        // Actualiza el cursor incluso si pulledCount == 0: significa que no
        // había novedades, no que falló. Evita re-descargar en el próximo sync.
        await _saveLastSyncTimestamp();
      }

      // Reportar error solo si ambas operaciones fallaron.
      final bothFailed = pushError != null && pullError != null;
      final errorMsg = bothFailed ? 'Push: $pushError | Pull: $pullError' : null;

      final result = SyncResult(
        state: bothFailed ? SyncState.error : SyncState.success,
        pushedCount: pushedCount,
        pulledCount: pulledCount,
        errorMessage: errorMsg,
      );
      _stateController.add(result);
      return result;
    } catch (e) {
      // Error inesperado fuera de push/pull (ej. error al acceder a Hive).
      debugPrint('SyncManager unexpected error: $e');
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
  // Hydration — descarga inicial completa (una sola vez por usuario)
  // ---------------------------------------------------------------------------

  static const _hydratedKeyPrefix = 'quick_finance_hydrated_';

  /// Descarga todas las transacciones si aún no se ha hidratado para
  /// [_userId]. Devuelve el número de transacciones descargadas (0 si no-op).
  Future<int> _hydrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_hydratedKeyPrefix$_userId';
    if (prefs.getBool(key) ?? false) return 0; // ya hidratado

    final remote = await _remoteDataSource.fetchTransactions(
      _userId!, // pull completo: sin updatedAfter
    );

    if (remote.isNotEmpty) {
      await _localDataSource.saveTransactions(
        remote.map((t) => t.copyWith(syncStatus: SyncStatus.synced)).toList(),
      );
    }

    await prefs.setBool(key, true);
    await _saveLastSyncTimestamp(); // el próximo syncNow será delta
    return remote.length;
  }

  // ---------------------------------------------------------------------------
  // Pull — descargar novedades
  // ---------------------------------------------------------------------------

  Future<int> _pull() async {
    final lastSync = await _getLastSyncTimestamp();

    final remoteTransactions = await _remoteDataSource.fetchTransactions(
      _userId!,
      updatedAfter: lastSync,
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
    if (_userId == null) return DateTime.fromMillisecondsSinceEpoch(0);
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_lastSyncKey(_userId!));
    return stored != null
        ? (DateTime.tryParse(stored) ?? DateTime.fromMillisecondsSinceEpoch(0))
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _saveLastSyncTimestamp() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey(_userId!), DateTime.now().toIso8601String());
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  void dispose() {
    stopConnectivityListener();
    _stateController.close();
  }
}
