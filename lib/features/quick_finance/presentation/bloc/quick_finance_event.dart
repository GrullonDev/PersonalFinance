import 'package:equatable/equatable.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/quick_finance/domain/parsers/quick_entry_parser.dart'
    show QuickEntryParser;
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/balance_summary_entity.dart';

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
  final String? rawInput;

  /// Fecha real del pago cuando se detectó automáticamente.
  final DateTime? occurredAt;

  /// Origen de un registro automático (p. ej. "Google Wallet"); `null` si
  /// lo escribió el usuario.
  final String? autoSourceLabel;

  const AddTransactionRequested({
    required this.amount,
    required this.type,
    required this.note,
    this.category,
    this.rawInput,
    this.occurredAt,
    this.autoSourceLabel,
  });

  @override
  List<Object?> get props => [
    amount,
    type,
    note,
    category,
    rawInput,
    occurredAt,
    autoSourceLabel,
  ];
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

  // ignore: avoid_positional_boolean_parameters
  const ConnectivityChanged(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

// ---------------------------------------------------------------------------
// Auto-capture events
// ---------------------------------------------------------------------------

/// Emitido cuando el AutoCaptureService detecta un pago; lo encola para
/// revisión del usuario antes de persistir.
class AutoCaptureReceived extends QuickFinanceEvent {
  const AutoCaptureReceived(this.capture);
  final AutoCapturedTransaction capture;

  @override
  List<Object?> get props => [capture];
}

/// El usuario confirmó (y opcionalmente editó) un pago auto-capturado.
class AutoCaptureConfirmed extends QuickFinanceEvent {
  const AutoCaptureConfirmed(
    this.capture, {
    this.editedNote,
    this.editedCategoryId,
    this.editedAmount,
  });
  final AutoCapturedTransaction capture;
  final String? editedNote;
  final String? editedCategoryId;
  final double? editedAmount;

  @override
  List<Object?> get props => [capture, editedNote, editedCategoryId, editedAmount];
}

/// El usuario descartó un pago auto-capturado; no se persiste.
class AutoCaptureDismissed extends QuickFinanceEvent {
  const AutoCaptureDismissed(this.capture);
  final AutoCapturedTransaction capture;

  @override
  List<Object?> get props => [capture];
}

/// Evento interno: resultado de la verificación de permisos en la plataforma.
/// No debe ser despachado desde fuera del BLoC.
class AutoCapturePermissionFlags extends QuickFinanceEvent {
  const AutoCapturePermissionFlags({
    required this.needsNotificationAccess,
    required this.needsShortcutsSetup,
  });
  final bool needsNotificationAccess;
  final bool needsShortcutsSetup;

  @override
  List<Object?> get props => [needsNotificationAccess, needsShortcutsSetup];
}
