import 'package:personal_finance/core/data/models/syncable_model.dart';
import 'package:personal_finance/core/utils/input_sanitizer.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';

class TransactionBackendModel extends SyncableModel {
  final String tipo; // ingreso | gasto
  final String monto; // keep string to preserve precision
  final String descripcion;
  final DateTime fecha;
  final String categoriaId;
  final bool esRecurrente;
  final int? profileId;
  final String? profileType;

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
    this.profileType,
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
    // Support both legacy schema (tipo/monto/descripcion/fecha/categoria_id)
    // and MVP schema (type/amount/note/createdAt/categoryId) written by Quick Finance.
    tipo: json['tipo']?.toString() ?? _mvpTypeToLegacy(json['type']),
    monto: (json['monto'] ?? json['amount'])?.toString() ?? '0',
    descripcion:
        json['descripcion']?.toString() ?? json['note']?.toString() ?? '',
    fecha:
        DateTime.tryParse(json['fecha']?.toString() ?? '') ??
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    categoriaId:
        (json['categoria_id'] ?? json['categoryId'])?.toString() ?? '0',
    esRecurrente:
        json['es_recurrente'] == true ||
        json['es_recurrente'] == 1 ||
        json['isRecurring'] == true,
    profileId:
        json['profile_id'] is int
            ? json['profile_id'] as int
            : int.tryParse(
                (json['profile_id'] ?? json['profileId'])?.toString() ?? '',
              ),
    profileType:
        (json['profile_type'] ?? json['profileType']) as String?,
  );

  static String _mvpTypeToLegacy(dynamic type) {
    final s = (type as String? ?? '').toLowerCase();
    if (s == 'income') return 'ingreso';
    if (s == 'expense') return 'gasto';
    return '';
  }

  @override
  Map<String, dynamic> toFirestore() => {
    ...super.toFirestore(),
    'tipo': tipo,
    'monto': monto,
    'descripcion': InputSanitizer.sanitizeText(descripcion),
    'fecha': fecha.toIso8601String(),
    'categoria_id': categoriaId,
    'es_recurrente': esRecurrente,
    'profile_id': profileId,
    'profile_type': profileType,
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
        profileType: entity.profileType,
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
    profileType: profileType,
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
    profileType,
  ];
}
