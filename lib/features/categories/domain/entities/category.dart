import 'package:personal_finance/core/domain/entities/syncable_entity.dart';

class Category extends SyncableEntity {
  final String nombre;
  final String tipo; // 'ingreso' | 'egreso'
  final int? profileId;

  const Category({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deviceId,
    required super.version,
    required this.nombre,
    required this.tipo,
    super.deletedAt,
    super.syncStatus,
    this.profileId,
  });

  Category copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deviceId,
    int? version,
    String? nombre,
    String? tipo,
    int? profileId,
  }) => Category(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    version: version ?? this.version,
    nombre: nombre ?? this.nombre,
    tipo: tipo ?? this.tipo,
    profileId: profileId ?? this.profileId,
  );

  @override
  List<Object?> get props => [...super.props, nombre, tipo, profileId];
}
