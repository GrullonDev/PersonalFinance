import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/sync/sync_manager.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/parsers/quick_entry_parser.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/add_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/delete_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/hydrate_current_user_transactions.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/watch_balance.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/watch_transactions.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/update_transaction.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_event.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_state.dart';

class QuickFinanceBloc extends Bloc<QuickFinanceEvent, QuickFinanceState> {
  final AddTransaction addTransaction;
  final DeleteTransaction deleteTransaction;
  final HydrateCurrentUserTransactions hydrateCurrentUserTransactions;
  final WatchBalance watchBalance;
  final WatchTransactions watchTransactions;
  final UpdateTransaction updateTransaction;
  final SyncManager syncManager;
  final AuthDataSource authDataSource;

  StreamSubscription<List<TransactionEntity>>? _transactionsSubscription;
  StreamSubscription<dynamic>? _balanceSubscription;
  StreamSubscription<SyncResult>? _syncSubscription;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  static const _parser = QuickEntryParser();

  QuickFinanceBloc({
    required this.addTransaction,
    required this.deleteTransaction,
    required this.hydrateCurrentUserTransactions,
    required this.watchBalance,
    required this.watchTransactions,
    required this.updateTransaction,
    required this.syncManager,
    required this.authDataSource,
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
    on<ConnectivityChanged>(_onConnectivityChanged);
  }

  // ---------------------------------------------------------------------------
  // Stream setup
  // ---------------------------------------------------------------------------

  Future<void> _onWatchDataRequested(
    WatchDataRequested event,
    Emitter<QuickFinanceState> emit,
  ) async {
    emit(state.copyWith(status: QuickFinanceStatus.loading));

    // Escuchar estado del SyncManager (no depende de auth)
    await _syncSubscription?.cancel();
    _syncSubscription = syncManager.syncStream.listen((result) {
      add(
        SyncStateChanged(
          isSyncing: result.state == SyncState.syncing,
          errorMessage:
              result.state == SyncState.error ? result.errorMessage : null,
        ),
      );
    });

    // Escuchar cambios de conectividad
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isOnline = results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
      add(ConnectivityChanged(isOnline));
    });

    // Los streams de datos se crean DESPUÉS de que el auth resuelva para
    // garantizar que siempre reciben el userId correcto. authStateChanges
    // emite inmediatamente el estado actual (resuelve la race condition) y
    // luego ante cada cambio (re-login, logout).
    await _authSubscription?.cancel();
    _authSubscription = authDataSource.authStateChanges.listen((uid) {
      if (uid != null) {
        syncManager.setUserId(uid);
        _subscribeDataStreams(uid);
        syncManager.syncOnAppStart(); // hydration + delta
        syncManager.startConnectivityListener();
      } else {
        _cancelDataStreams();
        syncManager.stopConnectivityListener();
      }
    });
  }

  void _subscribeDataStreams(String userId) {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = watchTransactions(userId: userId).listen(
      (transactions) => add(TransactionsObserved(transactions)),
      onError: (Object error, _) => add(
        SyncStateChanged(isSyncing: false, errorMessage: error.toString()),
      ),
    );

    _balanceSubscription?.cancel();
    _balanceSubscription = watchBalance(userId: userId).listen(
      (balance) => add(BalanceObserved(balance)),
    );
  }

  void _cancelDataStreams() {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = null;
    _balanceSubscription?.cancel();
    _balanceSubscription = null;
  }

  void _onTransactionsObserved(
    TransactionsObserved event,
    Emitter<QuickFinanceState> emit,
  ) {
    emit(
      state.copyWith(
        status: QuickFinanceStatus.success,
        transactions: event.transactions,
        clearError: true,
      ),
    );
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
    final syncSucceeded = !event.isSyncing && event.errorMessage == null;
    emit(
      state.copyWith(
        isSyncing: event.isSyncing,
        errorMessage: event.errorMessage,
        syncError: event.errorMessage,
        clearSyncError: event.errorMessage == null && !event.isSyncing,
        lastSyncAt: syncSucceeded ? DateTime.now() : state.lastSyncAt,
      ),
    );
  }

  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<QuickFinanceState> emit,
  ) {
    emit(state.copyWith(isOffline: !event.isOnline));
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
        add(
          AddTransactionRequested(
            amount: entry.amount,
            type: entry.type,
            note: entry.note,
            category: entry.category,
          ),
        );
      case ParseFailure(:final reason):
        emit(
          state.copyWith(
            status: QuickFinanceStatus.failure,
            errorMessage: reason,
          ),
        );
    }
  }

  Future<void> _onAddTransactionRequested(
    AddTransactionRequested event,
    Emitter<QuickFinanceState> emit,
  ) async {
    final uid = authDataSource.currentUserId;
    if (uid == null) {
      emit(state.copyWith(
        status: QuickFinanceStatus.failure,
        errorMessage: 'Sesión no disponible. Inicia sesión de nuevo.',
      ));
      return;
    }

    final transaction = TransactionEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: uid,
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
      emit(
        state.copyWith(
          status: QuickFinanceStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteTransactionRequested(
    DeleteTransactionRequested event,
    Emitter<QuickFinanceState> emit,
  ) async {
    try {
      await deleteTransaction(event.id);
    } catch (e) {
      emit(
        state.copyWith(
          status: QuickFinanceStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateTransactionRequested(
    UpdateTransactionRequested event,
    Emitter<QuickFinanceState> emit,
  ) async {
    try {
      await updateTransaction(event.transaction);
    } catch (e) {
      emit(
        state.copyWith(
          status: QuickFinanceStatus.failure,
          errorMessage: e.toString(),
        ),
      );
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
    _authSubscription?.cancel();
    _connectivitySubscription?.cancel();
    syncManager.stopConnectivityListener();
    return super.close();
  }
}
