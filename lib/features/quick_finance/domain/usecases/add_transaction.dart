import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/repositories/quick_finance_repository.dart';

class AddTransaction {
  final QuickFinanceRepository repository;

  AddTransaction(this.repository);

  Future<void> call(TransactionEntity transaction) =>
      repository.addTransaction(transaction);
}
