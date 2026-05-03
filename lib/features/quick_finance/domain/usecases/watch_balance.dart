import '../../domain/entities/balance_summary_entity.dart';
import '../../domain/repositories/quick_finance_repository.dart';

class WatchBalance {
  final QuickFinanceRepository repository;

  WatchBalance(this.repository);

  Stream<BalanceSummaryEntity> call({required String userId}) {
    return repository.watchBalance(userId: userId);
  }
}
