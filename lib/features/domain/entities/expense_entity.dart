import 'package:personal_finance/features/domain/entities/transaction_entity.dart';

/// Entidad que representa un gasto
class ExpenseEntity extends TransactionEntity {
  final String category;
  final String? notes;

  const ExpenseEntity({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deviceId,
    required super.version,
    required super.title,
    required super.amount,
    required super.date,
    required this.category,
    super.deletedAt,
    super.syncStatus,
    super.description,
    this.notes,
  });

  @override
  String get transactionType => 'expense';

  @override
  List<Object?> get props => [...super.props, category, notes];

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
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deviceId,
    int? version,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? description,
    String? notes,
  }) => ExpenseEntity(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    version: version ?? this.version,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    category: category ?? this.category,
    description: description ?? this.description,
    notes: notes ?? this.notes,
  );
}
