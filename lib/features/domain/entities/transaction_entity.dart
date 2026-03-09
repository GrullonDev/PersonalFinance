import 'package:personal_finance/core/domain/entities/syncable_entity.dart';
import 'package:personal_finance/utils/currency_helper.dart';

enum TransactionType { income, expense }

/// Entidad base para todas las transacciones financieras
abstract class TransactionEntity extends SyncableEntity {
  final String title;
  final double amount;
  final DateTime date;
  final String? description;

  const TransactionEntity({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deviceId,
    required super.version,
    required this.title,
    required this.amount,
    required this.date,
    super.deletedAt,
    super.syncStatus,
    this.description,
  });

  @override
  List<Object?> get props => [...super.props, title, amount, date, description];

  /// Verifica si la transacción es válida
  bool get isValid => title.isNotEmpty && amount > 0;

  /// Obtiene el tipo de transacción
  String get transactionType;

  String get formattedDate =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  /// Formatea el monto para mostrar
  String get formattedAmount => '${CurrencyHelper.symbol}${amount.toStringAsFixed(2)}';

  /// Verifica si la transacción es reciente (últimos 7 días)
  bool get isRecent {
    final DateTime now = DateTime.now();
    final DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));
    return date.isAfter(sevenDaysAgo);
  }
}
