import 'package:equatable/equatable.dart';

/// Entidad base para todas las transacciones financieras
abstract class TransactionEntity extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String? description;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.description,
  });

  @override
  List<Object?> get props => <Object?>[id, title, amount, date, description];

  /// Verifica si la transacción es válida
  bool get isValid => title.isNotEmpty && amount > 0;

  /// Obtiene el tipo de transacción
  String get transactionType;

  /// Formatea el monto para mostrar
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  /// Verifica si la transacción es reciente (últimos 7 días)
  bool get isRecent {
    final DateTime now = DateTime.now();
    final DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));
    return date.isAfter(sevenDaysAgo);
  }
} 