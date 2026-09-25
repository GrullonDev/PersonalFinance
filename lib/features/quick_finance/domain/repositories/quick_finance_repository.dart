import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/balance_summary_entity.dart';

abstract class QuickFinanceRepository {
  /// Stream local-first: emite inmediatamente desde Hive y dispara un fetch
  /// remoto en segundo plano si no hay datos en caché para [userId].
  /// Nunca mezcla transacciones de usuarios distintos.
  Stream<List<TransactionEntity>> watchTransactions({required String userId});

  /// Balance calculado sobre el stream local de [userId].
  Stream<BalanceSummaryEntity> watchBalance({required String userId});

  Future<void> addTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
  Future<void> syncPendingTransactions();
}
