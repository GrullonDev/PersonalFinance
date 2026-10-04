import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:personal_finance/core/services/device_service.dart';
import 'package:personal_finance/features/quick_finance/data/services/spending_alert_service.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';

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
  final DeviceService deviceService;

  StreamSubscription<List<TransactionEntity>>? _transactionsSubscription;
  StreamSubscription<dynamic>? _balanceSubscription;
  StreamSubscription<SyncResult>? _syncSubscription;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<AutoCapturedTransaction>? _autoCaptureSubscription;

  static const _parser = QuickEntryParser();
  int _autoSeq = 0;

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
    required this.deviceService,
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
    on<AutoCaptureReceived>(_onAutoCaptureReceived);
    on<AutoCaptureConfirmed>(_onAutoCaptureConfirmed);
    on<AutoCaptureDismissed>(_onAutoCaptureDismissed);
    on<AutoCapturePermissionFlags>(_onAutoCapturePermissionFlags);
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
      final isOnline =
          results.isNotEmpty &&
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
      onError:
          (Object error, _) => add(
            SyncStateChanged(isSyncing: false, errorMessage: error.toString()),
          ),
    );

    _balanceSubscription?.cancel();
    _balanceSubscription = watchBalance(
      userId: userId,
    ).listen((balance) => add(BalanceObserved(balance)));

    _subscribeAutoCapture();
  }

  /// Registra los pagos detectados automáticamente (Google Wallet, bancos,
  /// atajos de Apple Pay) en la cola pendiente para revisión del usuario.
  void _subscribeAutoCapture() {
    if (!GetIt.instance.isRegistered<AutoCaptureService>()) return;
    final service = GetIt.instance<AutoCaptureService>();
    _autoCaptureSubscription?.cancel();
    _autoCaptureSubscription = service.captured.listen(
      (tx) => add(AutoCaptureReceived(tx)),
    );
    service.start();
    unawaited(service.processPending());
    unawaited(_checkCapturePlatformSetup(service));
  }

  Future<void> _checkCapturePlatformSetup(AutoCaptureService service) async {
    try {
      bool needsNotif = false;
      bool needsShortcuts = false;

      if (_isAndroid()) {
        final granted = await service.isAccessGranted();
        if (!granted && GetIt.instance.isRegistered<SharedPreferences>()) {
          final prefs = GetIt.instance<SharedPreferences>();
          final suppressUntil = prefs.getInt(
            'auto_capture_notification_suppress_until',
          );
          final now = DateTime.now().millisecondsSinceEpoch;
          if (suppressUntil == null || now > suppressUntil) {
            needsNotif = true;
          }
        }
      } else if (_isIOS()) {
        if (GetIt.instance.isRegistered<SharedPreferences>()) {
          final prefs = GetIt.instance<SharedPreferences>();
          final done =
              prefs.getBool('auto_capture_shortcuts_setup_done') ?? false;
          if (!done) needsShortcuts = true;
        }
      }

      if (needsNotif || needsShortcuts) {
        add(
          AutoCapturePermissionFlags(
            needsNotificationAccess: needsNotif,
            needsShortcutsSetup: needsShortcuts,
          ),
        );
      }
    } catch (_) {}
  }

  bool _isAndroid() {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  bool _isIOS() {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  void _cancelDataStreams() {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = null;
    _balanceSubscription?.cancel();
    _balanceSubscription = null;
    _autoCaptureSubscription?.cancel();
    _autoCaptureSubscription = null;
  }

  // ---------------------------------------------------------------------------
  // Auto-capture handlers
  // ---------------------------------------------------------------------------

  void _onAutoCaptureReceived(
    AutoCaptureReceived event,
    Emitter<QuickFinanceState> emit,
  ) {
    emit(state.copyWith(
      pendingCaptures: [...state.pendingCaptures, event.capture],
    ));
  }

  Future<void> _onAutoCaptureConfirmed(
    AutoCaptureConfirmed event,
    Emitter<QuickFinanceState> emit,
  ) async {
    final capture = event.capture;
    final note = event.editedNote ?? capture.note;
    final category = event.editedCategoryId ?? capture.category;
    final amount = event.editedAmount ?? capture.amount;

    // Remove from queue immediately so UI updates without waiting for save
    emit(state.copyWith(
      pendingCaptures:
          state.pendingCaptures.where((c) => c != capture).toList(),
    ));

    add(AddTransactionRequested(
      amount: amount,
      type: capture.type,
      note: note,
      category: category,
      occurredAt: capture.occurredAt,
      autoSourceLabel: capture.sourceLabel,
    ));
  }

  void _onAutoCaptureDismissed(
    AutoCaptureDismissed event,
    Emitter<QuickFinanceState> emit,
  ) {
    emit(state.copyWith(
      pendingCaptures:
          state.pendingCaptures.where((c) => c != event.capture).toList(),
    ));
  }

  void _onAutoCapturePermissionFlags(
    AutoCapturePermissionFlags event,
    Emitter<QuickFinanceState> emit,
  ) {
    emit(state.copyWith(
      needsNotificationAccess: event.needsNotificationAccess,
      needsShortcutsSetup: event.needsShortcutsSetup,
    ));
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
    _checkSpendingDeviations(event.transactions);
  }

  /// Lanza (sin bloquear la UI) la detección de desvíos de gasto; el servicio
  /// notifica cada desvío una sola vez por mes.
  void _checkSpendingDeviations(List<TransactionEntity> transactions) {
    if (!GetIt.instance.isRegistered<SpendingAlertService>()) return;
    unawaited(
      GetIt.instance<SpendingAlertService>().evaluate(
        transactions,
        currencySymbol: CurrencyHelper.symbol,
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
            category:
                entry.category != null
                    ? InputSanitizer.sanitizeText(
                      entry.category!,
                      maxLength: 50,
                    )
                    : null,
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
      emit(
        state.copyWith(
          status: QuickFinanceStatus.failure,
          errorMessage: 'Sesión no disponible. Inicia sesión de nuevo.',
        ),
      );
      return;
    }

    final isAuto = event.autoSourceLabel != null;
    final transaction = TransactionEntity(
      // Las capturas automáticas pueden llegar varias en el mismo milisegundo.
      id:
          isAuto
              ? '${DateTime.now().millisecondsSinceEpoch}-${_autoSeq++}'
              : DateTime.now().millisecondsSinceEpoch.toString(),
      userId: uid,
      type: event.type,
      amount: event.amount,
      note: InputSanitizer.sanitizeText(event.note),
      categoryId:
          event.category != null
              ? InputSanitizer.sanitizeText(event.category!, maxLength: 50)
              : null,
      createdAt: event.occurredAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      version: 1,
      deviceId: deviceService.deviceId,
    );

    try {
      await addTransaction(transaction);
      if (isAuto) {
        await _notifyAutoCaptured(transaction, event.autoSourceLabel!);
        return;
      }
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

  Future<void> _notifyAutoCaptured(
    TransactionEntity transaction,
    String sourceLabel,
  ) async {
    try {
      final isIncome = transaction.type == TransactionType.income;
      final amount =
          '${CurrencyHelper.symbol}${transaction.amount.toStringAsFixed(2)}';
      final category =
          transaction.categoryId != null ? ' · #${transaction.categoryId}' : '';
      await GetIt.instance<NotificationService>().local.showNotification(
        id: 'auto_${transaction.id}'.hashCode,
        title: isIncome ? '💰 Ingreso registrado' : '💳 Gasto registrado',
        body:
            '$amount${isIncome ? ' ·' : ' en'} ${transaction.note}$category ($sourceLabel). '
            'Toca para revisarlo o corregirlo.',
        payload: RoutePath.dashboard,
      );
    } catch (_) {}
  }

  Future<void> _updateGoalOrDebtIfMatching(
    TransactionEntity transaction,
    String? rawInput,
  ) async {
    final note = transaction.note;
    final amount = transaction.amount;
    if (note.trim().isEmpty || amount <= 0) return;

    final isNegative = rawInput != null && rawInput.trim().startsWith('-');
    final noteLower = note.trim().toLowerCase();

    final cleanedGoalName = _extractGoalName(note);
    final cleanedDebtName = _extractDebtName(note);

    final isMetaOnly = noteLower.startsWith('meta') && cleanedGoalName == null;
    final isDeudaOnly =
        noteLower.startsWith('deuda') && cleanedDebtName == null;

    bool updated = false;

    if (isMetaOnly) {
      final res = await goalRepository.getGoals();
      await res.fold((_) async {}, (goals) async {
        if (goals.length == 1) {
          await _updateGoalEntity(goals.first, amount, isNegative);
          updated = true;
        }
      });
    } else if (isDeudaOnly) {
      final res = await debtRepository.getDebts();
      await res.fold((_) async {}, (debts) async {
        if (debts.length == 1) {
          await _updateDebtEntity(debts.first, amount, isNegative);
          updated = true;
        }
      });
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
    return res.fold((_) => null, (goals) {
      final query = name.trim().toLowerCase();
      for (final goal in goals) {
        if (goal.nombre.trim().toLowerCase() == query) return goal;
      }
      if (query.length >= 3) {
        for (final goal in goals) {
          final goalName = goal.nombre.trim().toLowerCase();
          if (goalName.contains(query) || query.contains(goalName)) {
            return goal;
          }
        }
      }
      return null;
    });
  }

  Future<Debt?> _findDebtByName(String name) async {
    final res = await debtRepository.getDebts();
    return res.fold((_) => null, (debts) {
      final query = name.trim().toLowerCase();
      for (final debt in debts) {
        if (debt.name.trim().toLowerCase() == query) return debt;
      }
      if (query.length >= 3) {
        for (final debt in debts) {
          final debtName = debt.name.trim().toLowerCase();
          if (debtName.contains(query) || query.contains(debtName)) {
            return debt;
          }
        }
      }
      return null;
    });
  }

  /*   Future<void> _updateGoalByName(
    String name,
    double amount,
    bool isNegative,
  ) async {
    final goal = await _findGoalByName(name);
    if (goal != null) {
      await _updateGoalEntity(goal, amount, isNegative);
    }
  }

  Future<void> _updateDebtByName(
    String name,
    double amount,
    bool isNegative,
  ) async {
    final debt = await _findDebtByName(name);
    if (debt != null) {
      await _updateDebtEntity(debt, amount, isNegative);
    }
  } */

  Future<void> _updateGoalEntity(
    Goal goal,
    double amount,
    bool isNegative,
  ) async {
    final currentAmount = goal.actualAsDouble;
    final newAmount =
        isNegative ? (currentAmount - amount) : (currentAmount + amount);
    final finalAmount = newAmount < 0 ? 0.0 : newAmount;

    final updatedGoal = goal.copyWith(montoActual: finalAmount.toString());

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
          body:
              '¡Felicidades! Completaste tu meta "${goal.nombre}" (${CurrencyHelper.symbol}${finalAmount.toStringAsFixed(0)}). ¡Lo lograste! 🎉',
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

  Future<void> _updateDebtEntity(
    Debt debt,
    double amount,
    bool isNegative,
  ) async {
    final currentBalance = debt.currentBalance;
    // isNegative = transaction starts with '-' (expense/payment) → reduces debt balance
    // isNegative = false ('+' or unsigned = new debt added) → increases debt balance
    final newBalance =
        isNegative ? (currentBalance - amount) : (currentBalance + amount);
    final finalBalance = newBalance < 0 ? 0.0 : newBalance;

    final updatedDebt = debt.copyWith(
      currentBalance: finalBalance,
      updatedAt: DateTime.now(),
    );

    await debtRepository.updateDebt(updatedDebt);

    // Trigger Notification
    try {
      final notif = GetIt.instance<NotificationService>();
      final double oldPaidPct =
          debt.originalAmount > 0
              ? (1 - currentBalance / debt.originalAmount) * 100
              : 0;
      final double newPaidPct =
          debt.originalAmount > 0
              ? (1 - finalBalance / debt.originalAmount) * 100
              : 0;

      if (oldPaidPct < 100 && newPaidPct >= 100) {
        await notif.local.showNotification(
          id: debt.id.hashCode,
          title: '🎉 ¡Deuda Liquidada!',
          body:
              '¡Felicidades! Liquidaste completamente la deuda "${debt.name}" (${CurrencyHelper.symbol}${debt.originalAmount.toStringAsFixed(0)}). ¡Eres libre! 🎊',
          payload: RoutePath.debts,
        );
      }
    } catch (_) {}

    // Update DebtsBloc state directly — avoids a full Firestore re-fetch and
    // race conditions that caused the completed state not to appear visually.
    try {
      if (GetIt.instance.isRegistered<DebtsBloc>()) {
        GetIt.instance<DebtsBloc>().add(DebtStateUpdated(updatedDebt));
      }
    } catch (_) {}
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
    _autoCaptureSubscription?.cancel();
    syncManager.stopConnectivityListener();
    return super.close();
  }
}
