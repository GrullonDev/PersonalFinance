import 'package:equatable/equatable.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/balance_summary_entity.dart';

abstract class QuickFinanceEvent extends Equatable {
  const QuickFinanceEvent();

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------------------------
// User-triggered events
// ---------------------------------------------------------------------------

/// Inicia la observación de transacciones y balance desde el datasource local.
class WatchDataRequested extends QuickFinanceEvent {
  const WatchDataRequested();
}

/// Texto crudo del campo de entrada rápida.
/// El BLoC lo parsea con [QuickEntryParser]; emite error si es inválido.
class RawEntrySubmitted extends QuickFinanceEvent {
  final String rawInput;

  const RawEntrySubmitted(this.rawInput);

  @override
  List<Object?> get props => [rawInput];
}

/// Solicita agregar una transacción ya parseada. El BLoC construye la entidad.
class AddTransactionRequested extends QuickFinanceEvent {
  final double amount;
  final TransactionType type;
  final String note;
  final String? category;

  const AddTransactionRequested({
    required this.amount,
    required this.type,
    required this.note,
    this.category,
  });

  @override
  List<Object?> get props => [amount, type, note, category];
}

/// Solicita eliminar (soft-delete) una transacción por su id.
class DeleteTransactionRequested extends QuickFinanceEvent {
  final String id;

  const DeleteTransactionRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Solicita actualizar una transacción.
class UpdateTransactionRequested extends QuickFinanceEvent {
  final TransactionEntity transaction;

  const UpdateTransactionRequested(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Dispara la sincronización manual (botón / pull-to-refresh).
class SyncTransactionsRequested extends QuickFinanceEvent {
  const SyncTransactionsRequested();
}

// ---------------------------------------------------------------------------
// Stream-driven events (internos, disparados por los streams de Hive)
// ---------------------------------------------------------------------------

/// Emitido cada vez que el stream de transacciones locales produce un nuevo valor.
class TransactionsObserved extends QuickFinanceEvent {
  final List<TransactionEntity> transactions;

  const TransactionsObserved(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

/// Emitido cada vez que el stream de balance produce un nuevo valor.
class BalanceObserved extends QuickFinanceEvent {
  final BalanceSummaryEntity balance;

  const BalanceObserved(this.balance);

  @override
  List<Object?> get props => [balance];
}

/// Emitido cuando cambia el estado de sincronización.
class SyncStateChanged extends QuickFinanceEvent {
  final bool isSyncing;
  final String? errorMessage;

  const SyncStateChanged({required this.isSyncing, this.errorMessage});

  @override
  List<Object?> get props => [isSyncing, errorMessage];
}

/// Emitido cuando cambia el estado de conectividad.
class ConnectivityChanged extends QuickFinanceEvent {
  final bool isOnline;

  const ConnectivityChanged(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}
