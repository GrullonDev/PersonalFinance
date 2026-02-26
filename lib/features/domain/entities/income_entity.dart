import 'package:personal_finance/features/domain/entities/transaction_entity.dart';

/// Entidad que representa un ingreso
class IncomeEntity extends TransactionEntity {
  final String source;
  final String? notes;

  const IncomeEntity({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deviceId,
    required super.version,
    required super.title,
    required super.amount,
    required super.date,
    required this.source,
    super.deletedAt,
    super.syncStatus,
    super.description,
    this.notes,
  });

  @override
  String get transactionType => 'income';

  @override
  List<Object?> get props => [...super.props, source, notes];

  /// Verifica si el ingreso proviene de una fuente específica
  bool isFromSource(String sourceName) =>
      source.toLowerCase() == sourceName.toLowerCase();

  /// Obtiene el color asociado a la fuente de ingreso
  String get sourceColor {
    switch (source.toLowerCase()) {
      case 'salario':
      case 'trabajo':
        return '#4CAF50';
      case 'freelance':
        return '#2196F3';
      case 'inversiones':
        return '#FF9800';
      case 'negocio':
        return '#9C27B0';
      case 'regalo':
        return '#E91E63';
      default:
        return '#4CAF50';
    }
  }

  /// Crea una copia con nuevos valores
  IncomeEntity copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deviceId,
    int? version,
    String? title,
    double? amount,
    DateTime? date,
    String? source,
    String? description,
    String? notes,
  }) => IncomeEntity(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    version: version ?? this.version,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    source: source ?? this.source,
    description: description ?? this.description,
    notes: notes ?? this.notes,
  );
}
