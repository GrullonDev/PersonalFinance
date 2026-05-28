import 'package:personal_finance/core/data/models/syncable_model.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';

class BudgetModel extends SyncableModel {
  final String nombre;
  final String montoTotal; // keep as string to avoid precision issues
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? profileId;

  const BudgetModel({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deviceId,
    required super.version,
    required this.nombre,
    required this.montoTotal,
    required this.fechaInicio,
    required this.fechaFin,
    super.deletedAt,
    super.syncStatus,
    this.profileId,
  });

  factory BudgetModel.fromFirestore(Map<String, dynamic> json) => BudgetModel(
    id: json['id'] as String,
    createdAt: dateTimeFromTimestamp(json['createdAt']),
    updatedAt: dateTimeFromTimestamp(json['updatedAt']),
    deletedAt:
        json['deletedAt'] != null
            ? dateTimeFromTimestamp(json['deletedAt'])
            : null,
    deviceId: json['deviceId'] as String? ?? 'unknown',
    version: json['version'] as int? ?? 1,
    nombre: json['nombre']?.toString() ?? '',
    montoTotal: json['monto_total']?.toString() ?? '0',
    fechaInicio:
        DateTime.tryParse(json['fecha_inicio']?.toString() ?? '') ??
        DateTime.now(),
    fechaFin:
        DateTime.tryParse(json['fecha_fin']?.toString() ?? '') ??
        DateTime.now(),
    profileId: json['profile_id']?.toString(),
  );

  @override
  Map<String, dynamic> toFirestore() => {
    ...super.toFirestore(),
    'nombre': nombre,
    'monto_total': montoTotal,
    'fecha_inicio': fechaInicio.toIso8601String(),
    'fecha_fin': fechaFin.toIso8601String(),
    'profile_id': profileId,
  };

  @override
  Map<String, dynamic> toJson() => toFirestore();

  factory BudgetModel.fromEntity(Budget entity) => BudgetModel(
    id: entity.id,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    deletedAt: entity.deletedAt,
    deviceId: entity.deviceId,
    version: entity.version,
    syncStatus: entity.syncStatus,
    nombre: entity.nombre,
    montoTotal: entity.montoTotal,
    fechaInicio: entity.fechaInicio,
    fechaFin: entity.fechaFin,
    profileId: entity.profileId,
  );

  Budget toEntity() => Budget(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    deviceId: deviceId,
    version: version,
    syncStatus: syncStatus,
    nombre: nombre,
    montoTotal: montoTotal,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    profileId: profileId,
  );

  @override
  List<Object?> get props => [
    ...super.props,
    nombre,
    montoTotal,
    fechaInicio,
    fechaFin,
    profileId,
  ];
}
