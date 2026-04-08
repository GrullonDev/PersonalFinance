import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/watch_balance.dart';
import '../../domain/usecases/watch_transactions.dart';
import '../../domain/usecases/sync_pending_transactions.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/balance_summary_entity.dart';
import 'quick_finance_event.dart';
import 'quick_finance_state.dart';

class QuickFinanceBloc extends Bloc<QuickFinanceEvent, QuickFinanceState> {
  final AddTransaction addTransaction;
  final DeleteTransaction deleteTransaction;
  final WatchBalance watchBalance;
  final WatchTransactions watchTransactions;
  final SyncPendingTransactions syncPendingTransactions;

  StreamSubscription<List<TransactionEntity>>? _transactionsSubscription;
  StreamSubscription<BalanceSummaryEntity>? _balanceSubscription;

  QuickFinanceBloc({
    required this.addTransaction,
    required this.deleteTransaction,
    required this.watchBalance,
    required this.watchTransactions,
    required this.syncPendingTransactions,
  }) : super(const QuickFinanceState()) {
    on<LoadQuickFinance>(_onLoadQuickFinance);
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<SyncTransactionsEvent>(_onSyncTransactions);
    on<LoadQuickFinanceData>(_onLoadQuickFinanceData);
    on<LoadBalanceData>(_onLoadBalanceData);
  }

  Future<void> _onLoadQuickFinance(
    LoadQuickFinance event,
    Emitter<QuickFinanceState> emit,
  ) async {
    emit(state.copyWith(status: QuickFinanceStatus.loading));

    await _transactionsSubscription?.cancel();
    _transactionsSubscription = watchTransactions().listen(
      (transactions) {
        add(LoadQuickFinanceData(transactions: transactions));
      },
      onError: (error) {
        // Log Error
      },
    );

    await _balanceSubscription?.cancel();
    _balanceSubscription = watchBalance().listen(
      (balance) {
        add(LoadBalanceData(balance: balance));
      },
      onError: (error) {
        // Log Error
      },
    );
  }

  void _onLoadQuickFinanceData(
    LoadQuickFinanceData event,
    Emitter<QuickFinanceState> emit,
  ) {
    emit(state.copyWith(
      status: QuickFinanceStatus.success,
      transactions: event.transactions,
    ));
  }

  void _onLoadBalanceData(
    LoadBalanceData event,
    Emitter<QuickFinanceState> emit,
  ) {
    emit(state.copyWith(
      status: QuickFinanceStatus.success,
      balance: event.balance,
    ));
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<QuickFinanceState> emit,
  ) async {
    try {
      await addTransaction(event.transaction);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<QuickFinanceState> emit,
  ) async {
    try {
      await deleteTransaction(event.id);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSyncTransactions(
    SyncTransactionsEvent event,
    Emitter<QuickFinanceState> emit,
  ) async {
    try {
      await syncPendingTransactions();
    } catch (e) {
      // Background sync errors don't necessarily update UI state as failure
    }
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    _balanceSubscription?.cancel();
    return super.close();
  }
}

// Internal events for stream data
class LoadQuickFinanceData extends QuickFinanceEvent {
  final List<TransactionEntity> transactions;
  const LoadQuickFinanceData({required this.transactions});
  
  @override
  List<Object?> get props => [transactions];
}

class LoadBalanceData extends QuickFinanceEvent {
  final BalanceSummaryEntity balance;
  const LoadBalanceData({required this.balance});
  
  @override
  List<Object?> get props => [balance];
}
