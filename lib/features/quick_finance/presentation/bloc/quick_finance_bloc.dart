import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/enums.dart';
import '../../data/sync/sync_manager.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/parsers/quick_entry_parser.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/watch_balance.dart';
import '../../domain/usecases/watch_transactions.dart';
import '../../domain/usecases/update_transaction.dart';
import 'quick_finance_event.dart';
import 'quick_finance_state.dart';

class QuickFinanceBloc extends Bloc<QuickFinanceEvent, QuickFinanceState> {
  final AddTransaction addTransaction;
  final DeleteTransaction deleteTransaction;
  final WatchBalance watchBalance;
  final WatchTransactions watchTransactions;
  final UpdateTransaction updateTransaction;
  final SyncManager syncManager;

  StreamSubscription<List<TransactionEntity>>? _transactionsSubscription;
  StreamSubscription<dynamic>? _balanceSubscription;
  StreamSubscription<SyncResult>? _syncSubscription;

  static const _parser = QuickEntryParser();

  QuickFinanceBloc({
    required this.addTransaction,
    required this.deleteTransaction,
    required this.watchBalance,
    required this.watchTransactions,
    required this.updateTransaction,
    required this.syncManager,
  }) : super(const QuickFinanceState()) {
    on<WatchDataRequested>(_onWatchDataRequested);
    on<TransactionsObserved>(_onTransactionsObserved);
    on<BalanceObserved>(_onBalanceObserved);
    on<RawEntrySubmitted>(_onRawEntrySubmitted);
    on<AddTransactionRequested>(_onAddTransactionRequested);
    on<DeleteTransactionRequested>(_onDeleteTransactionRequested);
    on<UpdateTransactionRequested>(_onUpdateTransactionRequested);
    on<SyncTransactionsRequested>(_onSyncTransactionsRequested);
    on<SyncStateChanged>(_onSyncStateChanged);
  }

  // ---------------------------------------------------------------------------
  // Stream setup
  // ---------------------------------------------------------------------------

  Future<void> _onWatchDataRequested(
    WatchDataRequested event,
    Emitter<QuickFinanceState> emit,
  ) async {
    emit(state.copyWith(status: QuickFinanceStatus.loading));

    // Escuchar transacciones locales
    await _transactionsSubscription?.cancel();
    _transactionsSubscription = watchTransactions().listen(
      (transactions) => add(TransactionsObserved(transactions)),
      onError: (Object error, _) => emit(
        state.copyWith(
          status: QuickFinanceStatus.failure,
          errorMessage: error.toString(),
        ),
      ),
    );

    // Escuchar balance
    await _balanceSubscription?.cancel();
    _balanceSubscription = watchBalance().listen(
      (balance) => add(BalanceObserved(balance)),
    );

    // Escuchar estado del SyncManager
    await _syncSubscription?.cancel();
    _syncSubscription = syncManager.syncStream.listen((result) {
      add(SyncStateChanged(
        isSyncing: result.state == SyncState.syncing,
        errorMessage:
            result.state == SyncState.error ? result.errorMessage : null,
      ));
    });

    // Trigger 1: sync al abrir la app
    syncManager.syncOnAppStart();

    // Trigger 2: escuchar cambios de conectividad
    syncManager.startConnectivityListener();
  }

  void _onTransactionsObserved(
    TransactionsObserved event,
    Emitter<QuickFinanceState> emit,
  ) {
    emit(state.copyWith(
      status: QuickFinanceStatus.success,
      transactions: event.transactions,
      clearError: true,
    ));
  }

  void _onBalanceObserved(
    BalanceObserved event,
    Emitter<QuickFinanceState> emit,
  ) {
    emit(state.copyWith(balance: event.balance));
  }

  void _onSyncStateChanged(
    SyncStateChanged event,
    Emitter<QuickFinanceState> emit,
  ) {
    emit(state.copyWith(
      isSyncing: event.isSyncing,
      errorMessage: event.errorMessage,
    ));
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Parsea el texto crudo y despacha [AddTransactionRequested] si es válido,
  /// o emite [QuickFinanceStatus.failure] con la razón si es inválido.
  void _onRawEntrySubmitted(
    RawEntrySubmitted event,
    Emitter<QuickFinanceState> emit,
  ) {
    final result = _parser.parse(event.rawInput);
    switch (result) {
      case ParseSuccess(:final entry):
        add(AddTransactionRequested(
          amount: entry.amount,
          type: entry.type,
          note: entry.note,
          category: entry.category,
        ));
      case ParseFailure(:final reason):
        emit(state.copyWith(
          status: QuickFinanceStatus.failure,
          errorMessage: reason,
        ));
    }
  }

  Future<void> _onAddTransactionRequested(
    AddTransactionRequested event,
    Emitter<QuickFinanceState> emit,
  ) async {
    final transaction = TransactionEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current-user', // TODO: inject from AuthBloc
      type: event.type,
      amount: event.amount,
      note: event.note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      version: 1,
      deviceId: 'device', // TODO: inject from DeviceInfoService
    );

    try {
      await addTransaction(transaction);
    } catch (e) {
      emit(state.copyWith(
        status: QuickFinanceStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteTransactionRequested(
    DeleteTransactionRequested event,
    Emitter<QuickFinanceState> emit,
  ) async {
    try {
      await deleteTransaction(event.id);
    } catch (e) {
      emit(state.copyWith(
        status: QuickFinanceStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateTransactionRequested(
    UpdateTransactionRequested event,
    Emitter<QuickFinanceState> emit,
  ) async {
    try {
      await updateTransaction(event.transaction);
    } catch (e) {
      emit(state.copyWith(
        status: QuickFinanceStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Trigger 3: Sync manual (botón / pull-to-refresh)
  // ---------------------------------------------------------------------------

  Future<void> _onSyncTransactionsRequested(
    SyncTransactionsRequested event,
    Emitter<QuickFinanceState> emit,
  ) async {
    // SyncManager se encarga — el estado llega vía SyncStateChanged
    await syncManager.syncNow();
  }

  // ---------------------------------------------------------------------------

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    _balanceSubscription?.cancel();
    _syncSubscription?.cancel();
    syncManager.stopConnectivityListener();
    return super.close();
  }
}
