import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/repositories/quick_finance_repository.dart';

class WatchTransactions {
  final QuickFinanceRepository repository;

  WatchTransactions(this.repository);

  Stream<List<TransactionEntity>> call({required String userId}) =>
      repository.watchTransactions(userId: userId);
}
