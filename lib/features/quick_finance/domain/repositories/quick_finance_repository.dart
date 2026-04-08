import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/balance_summary_entity.dart';

abstract class QuickFinanceRepository {
  Stream<List<TransactionEntity>> watchTransactions();
  Future<void> addTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
  
  Stream<BalanceSummaryEntity> watchBalance();
  Future<void> syncPendingTransactions();
}
