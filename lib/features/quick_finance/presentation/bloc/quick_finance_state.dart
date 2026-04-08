import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/balance_summary_entity.dart';

enum QuickFinanceStatus { initial, loading, success, failure }

class QuickFinanceState extends Equatable {
  final QuickFinanceStatus status;
  final List<TransactionEntity> transactions;
  final BalanceSummaryEntity balance;
  final String? errorMessage;

  const QuickFinanceState({
    this.status = QuickFinanceStatus.initial,
    this.transactions = const [],
    this.balance = const BalanceSummaryEntity(
      totalBalance: 0,
      totalIncome: 0,
      totalExpenses: 0,
    ),
    this.errorMessage,
  });

  QuickFinanceState copyWith({
    QuickFinanceStatus? status,
    List<TransactionEntity>? transactions,
    BalanceSummaryEntity? balance,
    String? errorMessage,
  }) {
    return QuickFinanceState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      balance: balance ?? this.balance,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, transactions, balance, errorMessage];
}
