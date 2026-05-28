import 'package:equatable/equatable.dart';
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
  }) => QuickFinanceState(
    status: status ?? this.status,
    transactions: transactions ?? this.transactions,
    balance: balance ?? this.balance,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    isSyncing: isSyncing ?? this.isSyncing,
    isOffline: isOffline ?? this.isOffline,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    syncError: clearSyncError ? null : (syncError ?? this.syncError),
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
  ];
}
