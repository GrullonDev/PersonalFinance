import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/quick_finance_repository.dart';

class UpdateTransaction {
  final QuickFinanceRepository repository;

  UpdateTransaction(this.repository);

  Future<void> call(TransactionEntity transaction) {
    return repository.updateTransaction(transaction);
  }
}
