import 'package:personal_finance/features/quick_finance/domain/repositories/quick_finance_repository.dart';

class DeleteTransaction {
  final QuickFinanceRepository repository;

  DeleteTransaction(this.repository);

  Future<void> call(String id) => repository.deleteTransaction(id);
}
