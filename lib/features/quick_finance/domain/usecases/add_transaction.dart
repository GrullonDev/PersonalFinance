import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/quick_finance_repository.dart';

class AddTransaction {
  final QuickFinanceRepository repository;

  AddTransaction(this.repository);

  Future<void> call(TransactionEntity transaction) {
    return repository.addTransaction(transaction);
  }
}
