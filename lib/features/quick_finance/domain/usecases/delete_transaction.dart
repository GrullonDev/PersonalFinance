import '../../domain/repositories/quick_finance_repository.dart';

class DeleteTransaction {
  final QuickFinanceRepository repository;

  DeleteTransaction(this.repository);

  Future<void> call(String id) {
    return repository.deleteTransaction(id);
  }
}
