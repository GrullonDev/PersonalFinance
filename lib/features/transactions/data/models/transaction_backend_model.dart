import 'package:personal_finance/core/data/models/syncable_model.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';

class TransactionBackendModel extends SyncableModel {
  final String tipo; // ingreso | gasto
  final String monto; // keep string to preserve precision
  final String descripcion;
  final DateTime fecha;
  final String categoriaId;
  final bool esRecurrente;
  final int? profileId;

  const TransactionBackendModel({
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

  factory TransactionBackendModel.fromFirestore(
    Map<String, dynamic> json,
  ) => TransactionBackendModel(
    id: json['id'] as String,
    createdAt: dateTimeFromTimestamp(json['createdAt']),
    updatedAt: dateTimeFromTimestamp(json['updatedAt']),
    deletedAt:
        json['deletedAt'] != null
            ? dateTimeFromTimestamp(json['deletedAt'])
            : null,
    deviceId: json['deviceId'] as String? ?? 'unknown',
    version: json['version'] as int? ?? 1,
    tipo: json['tipo']?.toString() ?? '',
    monto: json['monto']?.toString() ?? '0',
    descripcion: json['descripcion']?.toString() ?? '',
    fecha: DateTime.tryParse(json['fecha']?.toString() ?? '') ?? DateTime.now(),
    categoriaId: json['categoria_id']?.toString() ?? '0',
    esRecurrente: json['es_recurrente'] == true || json['es_recurrente'] == 1,
    profileId:
        json['profile_id'] is int
            ? json['profile_id'] as int
            : int.tryParse(json['profile_id']?.toString() ?? ''),
  );

  @override
  Map<String, dynamic> toFirestore() => {
    ...super.toFirestore(),
    'tipo': tipo,
    'monto': monto,
    'descripcion': descripcion,
    'fecha': fecha.toIso8601String(),
    'categoria_id': categoriaId,
    'es_recurrente': esRecurrente,
    'profile_id': profileId,
  };

  @override
  Map<String, dynamic> toJson() => toFirestore();

  factory TransactionBackendModel.fromEntity(TransactionBackend entity) =>
      TransactionBackendModel(
        id: entity.id,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        deletedAt: entity.deletedAt,
        deviceId: entity.deviceId,
        version: entity.version,
        syncStatus: entity.syncStatus,
        tipo: entity.tipo,
        monto: entity.monto,
        descripcion: entity.descripcion,
        fecha: entity.fecha,
        categoriaId: entity.categoriaId,
        esRecurrente: entity.esRecurrente,
        profileId: entity.profileId,
      );

  TransactionBackend toEntity() => TransactionBackend(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    deviceId: deviceId,
    version: version,
    syncStatus: syncStatus,
    tipo: tipo,
    monto: monto,
    descripcion: descripcion,
    fecha: fecha,
    categoriaId: categoriaId,
    esRecurrente: esRecurrente,
    profileId: profileId,
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
