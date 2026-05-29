import 'package:personal_finance/features/quick_finance/domain/entities/balance_summary_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/repositories/quick_finance_repository.dart';

class WatchBalance {
  final QuickFinanceRepository repository;

  WatchBalance(this.repository);

  Stream<BalanceSummaryEntity> call({required String userId}) =>
      repository.watchBalance(userId: userId);
}
