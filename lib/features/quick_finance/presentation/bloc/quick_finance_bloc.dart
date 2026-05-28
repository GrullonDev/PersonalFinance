import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/sync/sync_manager.dart';
import 'package:personal_finance/core/utils/input_sanitizer.dart';
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
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:personal_finance/core/services/notifications/notification_service.dart';
import 'package:personal_finance/utils/currency_helper.dart';
import 'package:personal_finance/features/goals/presentation/bloc/goals_bloc.dart';
import 'package:personal_finance/features/debts/presentation/bloc/debts_bloc.dart';
import 'package:personal_finance/features/debts/presentation/bloc/debts_event.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class QuickFinanceBloc extends Bloc<QuickFinanceEvent, QuickFinanceState> {
  final AddTransaction addTransaction;
  final DeleteTransaction deleteTransaction;
  final HydrateCurrentUserTransactions hydrateCurrentUserTransactions;
  final WatchBalance watchBalance;
  final WatchTransactions watchTransactions;
  final UpdateTransaction updateTransaction;
  final SyncManager syncManager;
  final AuthDataSource authDataSource;
  final GoalRepository goalRepository;
  final DebtRepository debtRepository;

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
    required this.goalRepository,
    required this.debtRepository,
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
            note: InputSanitizer.sanitizeText(entry.note),
            category: entry.category != null ? InputSanitizer.sanitizeText(entry.category!, maxLength: 50) : null,
            rawInput: event.rawInput,
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
      note: InputSanitizer.sanitizeText(event.note),
      categoryId: event.category != null ? InputSanitizer.sanitizeText(event.category!, maxLength: 50) : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      version: 1,
      deviceId: 'device', // TODO: inject from DeviceInfoService
    );

    try {
      await addTransaction(transaction);
      await _updateGoalOrDebtIfMatching(transaction, event.rawInput);
    } catch (e) {
      emit(
        state.copyWith(
          status: QuickFinanceStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _updateGoalOrDebtIfMatching(TransactionEntity transaction, String? rawInput) async {
    final note = transaction.note;
    final amount = transaction.amount;
    if (note.trim().isEmpty || amount <= 0) return;

    final isNegative = rawInput != null && rawInput.trim().startsWith('-');
    final noteLower = note.trim().toLowerCase();

    final cleanedGoalName = _extractGoalName(note);
    final cleanedDebtName = _extractDebtName(note);

    final isMetaOnly = noteLower.startsWith('meta') && cleanedGoalName == null;
    final isDeudaOnly = noteLower.startsWith('deuda') && cleanedDebtName == null;

    bool updated = false;

    if (isMetaOnly) {
      final res = await goalRepository.getGoals();
      await res.fold(
        (_) async {},
        (goals) async {
          if (goals.length == 1) {
            await _updateGoalEntity(goals.first, amount, isNegative);
            updated = true;
          }
        },
      );
    } else if (isDeudaOnly) {
      final res = await debtRepository.getDebts();
      await res.fold(
        (_) async {},
        (debts) async {
          if (debts.length == 1) {
            await _updateDebtEntity(debts.first, amount, isNegative);
            updated = true;
          }
        },
      );
    } else {
      if (cleanedGoalName != null) {
        final goal = await _findGoalByName(cleanedGoalName);
        if (goal != null) {
          await _updateGoalEntity(goal, amount, isNegative);
          updated = true;
        }
      }
      if (!updated && cleanedDebtName != null) {
        final debt = await _findDebtByName(cleanedDebtName);
        if (debt != null) {
          await _updateDebtEntity(debt, amount, isNegative);
          updated = true;
        }
      }
    }

    if (!updated) {
      // Fallback: search if the entire note matches a goal or a debt name (case-insensitive)
      final matchedGoal = await _findGoalByName(note);
      if (matchedGoal != null) {
        await _updateGoalEntity(matchedGoal, amount, isNegative);
      } else {
        final matchedDebt = await _findDebtByName(note);
        if (matchedDebt != null) {
          await _updateDebtEntity(matchedDebt, amount, isNegative);
        }
      }
    }
  }

  String? _extractGoalName(String note) {
    final trimmed = note.trim();
    final lowercase = trimmed.toLowerCase();
    final keywords = ['meta', 'ahorro'];
    for (final keyword in keywords) {
      if (lowercase.startsWith(keyword)) {
        var rest = trimmed.substring(keyword.length).trim();
        rest = rest.replaceFirst(RegExp(r'^[-:\s]+'), '').trim();

        bool cleaned;
        do {
          cleaned = false;
          final restLower = rest.toLowerCase();
          final fillers = [
            'para la',
            'para mi',
            'para',
            'de la',
            'de las',
            'de los',
            'de',
            'a la',
            'a las',
            'a los',
            'a',
            'mi',
            'mis',
          ];
          for (final filler in fillers) {
            if (restLower.startsWith(filler)) {
              final pattern = RegExp(
                '^${RegExp.escape(filler)}(\\s+|\$)',
                caseSensitive: false,
              );
              if (pattern.hasMatch(rest)) {
                rest = rest.replaceFirst(pattern, '').trim();
                rest = rest.replaceFirst(RegExp(r'^[-:\s]+'), '').trim();
                cleaned = true;
                break;
              }
            }
          }
        } while (cleaned && rest.isNotEmpty);

        if (rest.isNotEmpty) {
          return rest;
        }
      }
    }
    return null;
  }

  String? _extractDebtName(String note) {
    final trimmed = note.trim();
    final lowercase = trimmed.toLowerCase();
    final keywords = ['deuda', 'pago', 'abono', 'cuota'];
    for (final keyword in keywords) {
      if (lowercase.startsWith(keyword)) {
        var rest = trimmed.substring(keyword.length).trim();
        rest = rest.replaceFirst(RegExp(r'^[-:\s]+'), '').trim();

        bool cleaned;
        do {
          cleaned = false;
          final restLower = rest.toLowerCase();
          final fillers = [
            'minimo',
            'mínimo',
            'minima',
            'mínima',
            'de la',
            'de las',
            'de los',
            'de',
            'a la',
            'a las',
            'a los',
            'a',
            'mi',
            'mis',
          ];
          for (final filler in fillers) {
            if (restLower.startsWith(filler)) {
              final pattern = RegExp(
                '^${RegExp.escape(filler)}(\\s+|\$)',
                caseSensitive: false,
              );
              if (pattern.hasMatch(rest)) {
                rest = rest.replaceFirst(pattern, '').trim();
                rest = rest.replaceFirst(RegExp(r'^[-:\s]+'), '').trim();
                cleaned = true;
                break;
              }
            }
          }
        } while (cleaned && rest.isNotEmpty);

        if (rest.isNotEmpty) {
          return rest;
        }
      }
    }
    return null;
  }

  Future<Goal?> _findGoalByName(String name) async {
    final res = await goalRepository.getGoals();
    return res.fold(
      (_) => null,
      (goals) {
        final searchName = name.trim().toLowerCase();
        for (final goal in goals) {
          if (goal.nombre.trim().toLowerCase() == searchName) {
            return goal;
          }
        }
        return null;
      },
    );
  }

  Future<Debt?> _findDebtByName(String name) async {
    final res = await debtRepository.getDebts();
    return res.fold(
      (_) => null,
      (debts) {
        final searchName = name.trim().toLowerCase();
        for (final debt in debts) {
          if (debt.name.trim().toLowerCase() == searchName) {
            return debt;
          }
        }
        return null;
      },
    );
  }

  Future<void> _updateGoalByName(String name, double amount, bool isNegative) async {
    final goal = await _findGoalByName(name);
    if (goal != null) {
      await _updateGoalEntity(goal, amount, isNegative);
    }
  }

  Future<void> _updateDebtByName(String name, double amount, bool isNegative) async {
    final debt = await _findDebtByName(name);
    if (debt != null) {
      await _updateDebtEntity(debt, amount, isNegative);
    }
  }

  Future<void> _updateGoalEntity(Goal goal, double amount, bool isNegative) async {
    final currentAmount = goal.actualAsDouble;
    final newAmount = isNegative ? (currentAmount - amount) : (currentAmount + amount);
    final finalAmount = newAmount < 0 ? 0.0 : newAmount;

    final updatedGoal = goal.copyWith(
      montoActual: finalAmount.toString(),
    );

    await goalRepository.updateGoal(updatedGoal);

    // Trigger Notification
    try {
      final notif = GetIt.instance<NotificationService>();
      final double target = double.tryParse(goal.montoObjetivo) ?? 0.0;
      final double oldPct = target > 0 ? (currentAmount / target) * 100 : 0;
      final double newPct = target > 0 ? (finalAmount / target) * 100 : 0;

      if (oldPct < 100 && newPct >= 100) {
        await notif.local.showNotification(
          id: goal.id.hashCode,
          title: '🏆 ¡Meta Completada!',
          body: '¡Felicidades! Completaste tu meta "${goal.nombre}" (${CurrencyHelper.symbol}${finalAmount.toStringAsFixed(0)}). ¡Lo lograste! 🎉',
          payload: RoutePath.goalsCrud,
        );
      }
    } catch (_) {}

    // Reload GoalsBloc
    try {
      if (GetIt.instance.isRegistered<GoalsBloc>()) {
        GetIt.instance<GoalsBloc>().add(GoalsLoad());
      }
    } catch (_) {}
  }

  Future<void> _updateDebtEntity(Debt debt, double amount, bool isNegative) async {
    final currentBalance = debt.currentBalance;
    final newBalance = isNegative ? (currentBalance + amount) : (currentBalance - amount);
    final finalBalance = newBalance < 0 ? 0.0 : newBalance;

    final updatedDebt = debt.copyWith(
      currentBalance: finalBalance,
      updatedAt: DateTime.now(),
    );

    await debtRepository.updateDebt(updatedDebt);

    // Trigger Notification
    try {
      final notif = GetIt.instance<NotificationService>();
      final double oldPaidPct = debt.originalAmount > 0
          ? (1 - currentBalance / debt.originalAmount) * 100
          : 0;
      final double newPaidPct = debt.originalAmount > 0
          ? (1 - finalBalance / debt.originalAmount) * 100
          : 0;

      if (oldPaidPct < 100 && newPaidPct >= 100) {
        await notif.local.showNotification(
          id: debt.id.hashCode,
          title: '🎉 ¡Deuda Liquidada!',
          body: '¡Felicidades! Liquidaste completamente la deuda "${debt.name}" (${CurrencyHelper.symbol}${debt.originalAmount.toStringAsFixed(0)}). ¡Eres libre! 🎊',
          payload: RoutePath.debts,
        );
      }
    } catch (_) {}

    // Reload DebtsBloc
    try {
      if (GetIt.instance.isRegistered<DebtsBloc>()) {
        GetIt.instance<DebtsBloc>().add(DebtsLoad());
      }
    } catch (_) {}
  }

  int? _crossedGoalMilestone(double oldPct, double newPct) {
    int? highest;
    for (final int m in const <int>[50, 60, 70, 80, 90, 100]) {
      if (oldPct < m && newPct >= m) highest = m;
    }
    return highest;
  }

  String _goalMilestoneTitle(int pct) {
    if (pct == 100) return '🏆 ¡Meta Completada!';
    if (pct >= 80) return '🔥 ¡Casi lo logras!';
    if (pct >= 60) return '💪 ¡Muy buen progreso!';
    return '🚀 ¡Vas a la mitad!';
  }

  String _goalMilestoneBody(int pct, String nombre, double current, double target) {
    final String curr = '${CurrencyHelper.symbol}${current.toStringAsFixed(0)}';
    final String tgt = '${CurrencyHelper.symbol}${target.toStringAsFixed(0)}';
    switch (pct) {
      case 100:
        return '¡Felicidades! Completaste tu meta "$nombre" ($curr). ¡Lo lograste! 🎉';
      case 90:
        return '¡Ya llevas el 90% de "$nombre"! ($curr / $tgt). Un último esfuerzo. ✨';
      case 80:
        return '¡Increíble! Tienes el 80% de "$nombre" ($curr / $tgt). ¡La recta final! 💪';
      case 70:
        return '¡70% completado de "$nombre"! ($curr / $tgt). Vas muy bien. 💚';
      case 60:
        return '¡Llevas el 60% de "$nombre"! ($curr / $tgt). Más de la mitad. 🌟';
      default:
        return '¡Ya llevas el 50% de "$nombre"! ($curr / $tgt). La mitad del camino. 🚀';
    }
  }

  int? _crossedDebtMilestone(double oldPaidPct, double newPaidPct) {
    int? highest;
    for (final int m in const <int>[80, 100]) {
      if (oldPaidPct < m && newPaidPct >= m) highest = m;
    }
    return highest;
  }

  String _debtMilestoneTitle(int pct) =>
      pct == 100 ? '🎉 ¡Deuda Liquidada!' : '💪 ¡80% de la deuda pagado!';

  String _debtMilestoneBody(int pct, String nombre, double balance, double original) {
    final String sym = CurrencyHelper.symbol;
    if (pct == 100) {
      return '¡Felicidades! Liquidaste completamente la deuda "$nombre" ($sym${original.toStringAsFixed(0)}). ¡Eres libre! 🎊';
    }
    return '¡Increíble! Ya pagaste el 80% de "$nombre". Solo te quedan $sym${balance.toStringAsFixed(0)} de $sym${original.toStringAsFixed(0)}. ¡La recta final! 🔥';
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
