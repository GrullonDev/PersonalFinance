import 'package:personal_finance/features/domain/entities/transaction_entity.dart';

/// Entidad que representa un gasto
class ExpenseEntity extends TransactionEntity {
  final String category;
  final String? notes;

  const ExpenseEntity({
    required super.id,
    required super.title,
    required super.amount,
    required super.date,
    required this.category,
    super.description,
    this.notes,
  });

  @override
  String get transactionType => 'expense';

  @override
  List<Object?> get props => <Object?>[...super.props, category, notes];

  /// Verifica si el gasto es de una categoría específica
  bool isCategory(String categoryName) =>
      category.toLowerCase() == categoryName.toLowerCase();

  /// Obtiene el color asociado a la categoría
  String get categoryColor {
    switch (category.toLowerCase()) {
      case 'alimentación':
      case 'comida':
        return '#FF6B6B';
      case 'transporte':
        return '#4ECDC4';
      case 'entretenimiento':
        return '#45B7D1';
      case 'salud':
        return '#96CEB4';
      case 'educación':
        return '#FFEAA7';
      case 'vivienda':
        return '#DDA0DD';
      case 'ropa':
        return '#98D8C8';
      default:
        return '#A8A8A8';
    }
  }

  /// Crea una copia con nuevos valores
  ExpenseEntity copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? description,
    String? notes,
  }) => ExpenseEntity(
    id: id ?? this.id,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    category: category ?? this.category,
    description: description ?? this.description,
    notes: notes ?? this.notes,
  );
}
