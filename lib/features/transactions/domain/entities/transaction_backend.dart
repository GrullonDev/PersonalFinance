import 'package:personal_finance/core/domain/entities/syncable_entity.dart';

class TransactionBackend extends SyncableEntity {
  final String tipo; // ingreso | gasto
  final String monto; // string
  final String descripcion;
  final DateTime fecha;
  final String categoriaId;
  final bool esRecurrente;
  final int? profileId;

  const TransactionBackend({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deviceId,
    required super.version,
    required this.tipo,
    required this.monto,
    required this.descripcion,
    required this.fecha,
    required this.categoriaId,
    required this.esRecurrente,
    super.deletedAt,
    super.syncStatus,
    this.profileId,
  });

  TransactionBackend copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deviceId,
    int? version,
    String? tipo,
    String? monto,
    String? descripcion,
    DateTime? fecha,
    String? categoriaId,
    bool? esRecurrente,
    int? profileId,
  }) => TransactionBackend(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    version: version ?? this.version,
    tipo: tipo ?? this.tipo,
    monto: monto ?? this.monto,
    descripcion: descripcion ?? this.descripcion,
    fecha: fecha ?? this.fecha,
    categoriaId: categoriaId ?? this.categoriaId,
    esRecurrente: esRecurrente ?? this.esRecurrente,
    profileId: profileId ?? this.profileId,
  );

  double get montoAsDouble => double.tryParse(monto) ?? 0.0;

  @override
  List<Object?> get props => [
    ...super.props,
    tipo,
    monto,
    descripcion,
    fecha,
    categoriaId,
    esRecurrente,
    profileId,
  ];
}
