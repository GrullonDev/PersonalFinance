import 'package:personal_finance/features/quick_finance/domain/repositories/quick_finance_repository.dart';

class SyncPendingTransactions {
  final QuickFinanceRepository repository;

  SyncPendingTransactions(this.repository);

  Future<void> call() => repository.syncPendingTransactions();
}
