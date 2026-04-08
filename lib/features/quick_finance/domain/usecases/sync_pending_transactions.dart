import '../../domain/repositories/quick_finance_repository.dart';

class SyncPendingTransactions {
  final QuickFinanceRepository repository;

  SyncPendingTransactions(this.repository);

  Future<void> call() {
    return repository.syncPendingTransactions();
  }
}
