import 'package:personal_finance/features/quick_finance/data/sync/sync_manager.dart';

/// Descarga todas las transacciones del usuario autenticado desde Firestore
/// y las persiste en Hive (bootstrap local-first).
///
/// Es idempotente: si el usuario ya fue hidratado en este dispositivo,
/// la operación retorna inmediatamente sin tráfico de red.
class HydrateCurrentUserTransactions {
  final SyncManager syncManager;

  const HydrateCurrentUserTransactions(this.syncManager);

  Future<SyncResult> call() => syncManager.hydrateCurrentUserTransactions();
}
