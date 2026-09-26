import 'package:equatable/equatable.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/balance_summary_entity.dart';

enum QuickFinanceStatus { initial, loading, success, failure }

class QuickFinanceState extends Equatable {
  final QuickFinanceStatus status;
  final List<TransactionEntity> transactions;
  final BalanceSummaryEntity balance;
  final String? errorMessage;

  /// `true` cuando el SyncManager está ejecutando push/pull.
  final bool isSyncing;

  /// `true` cuando el dispositivo no tiene conexión a internet.
  final bool isOffline;

  /// Timestamp de la última sincronización exitosa.
  final DateTime? lastSyncAt;

  /// Mensaje del último error de sincronización (null si no hubo error).
  final String? syncError;

  /// Pagos auto-capturados pendientes de confirmación por el usuario.
  final List<AutoCapturedTransaction> pendingCaptures;

  /// Android: true cuando el permiso de notificaciones no está concedido y
  /// no está suprimido durante 7 días.
  final bool needsNotificationAccess;

  /// iOS: true cuando el usuario aún no configuró la automatización Shortcuts.
  final bool needsShortcutsSetup;

  const QuickFinanceState({
    this.status = QuickFinanceStatus.initial,
    this.transactions = const [],
    this.balance = const BalanceSummaryEntity(
      totalBalance: 0,
      totalIncome: 0,
      totalExpenses: 0,
    ),
    this.errorMessage,
    this.isSyncing = false,
    this.isOffline = false,
    this.lastSyncAt,
    this.syncError,
    this.pendingCaptures = const [],
    this.needsNotificationAccess = false,
    this.needsShortcutsSetup = false,
  });

  QuickFinanceState copyWith({
    QuickFinanceStatus? status,
    List<TransactionEntity>? transactions,
    BalanceSummaryEntity? balance,
    String? errorMessage,
    bool clearError = false,
    bool? isSyncing,
    bool? isOffline,
    DateTime? lastSyncAt,
    String? syncError,
    bool clearSyncError = false,
    List<AutoCapturedTransaction>? pendingCaptures,
    bool? needsNotificationAccess,
    bool? needsShortcutsSetup,
  }) => QuickFinanceState(
    status: status ?? this.status,
    transactions: transactions ?? this.transactions,
    balance: balance ?? this.balance,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    isSyncing: isSyncing ?? this.isSyncing,
    isOffline: isOffline ?? this.isOffline,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    syncError: clearSyncError ? null : (syncError ?? this.syncError),
    pendingCaptures: pendingCaptures ?? this.pendingCaptures,
    needsNotificationAccess:
        needsNotificationAccess ?? this.needsNotificationAccess,
    needsShortcutsSetup: needsShortcutsSetup ?? this.needsShortcutsSetup,
  );

  @override
  List<Object?> get props => [
    status,
    transactions,
    balance,
    errorMessage,
    isSyncing,
    isOffline,
    lastSyncAt,
    syncError,
    pendingCaptures,
    needsNotificationAccess,
    needsShortcutsSetup,
  ];
}
