import 'package:personal_finance/core/domain/entities/syncable_entity.dart';

class Budget extends SyncableEntity {
  final String nombre;
  final String montoTotal; // keep as string
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? profileId;

  const Budget({
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

  Budget copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deviceId,
    int? version,
    String? nombre,
    String? montoTotal,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? profileId,
  }) => Budget(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    version: version ?? this.version,
    nombre: nombre ?? this.nombre,
    montoTotal: montoTotal ?? this.montoTotal,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    profileId: profileId ?? this.profileId,
  );

  double get montoAsDouble => double.tryParse(montoTotal) ?? 0.0;

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
