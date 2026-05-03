import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/quick_finance_repository.dart';

class WatchTransactions {
  final QuickFinanceRepository repository;

  WatchTransactions(this.repository);

  Stream<List<TransactionEntity>> call({required String userId}) {
    return repository.watchTransactions(userId: userId);
  }
}
