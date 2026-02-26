import 'package:personal_finance/core/data/models/syncable_model.dart';
import 'package:personal_finance/features/categories/domain/entities/category.dart';

class CategoryModel extends SyncableModel {
  final String nombre;
  final String tipo;
  final int? profileId;

  const CategoryModel({
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

  factory CategoryModel.fromFirestore(Map<String, dynamic> json) =>
      CategoryModel(
        id: json['id'] as String,
        createdAt: dateTimeFromTimestamp(json['createdAt']),
        updatedAt: dateTimeFromTimestamp(json['updatedAt']),
        deletedAt:
            json['deletedAt'] != null
                ? dateTimeFromTimestamp(json['deletedAt'])
                : null,
        deviceId: json['deviceId'] as String? ?? '',
        version: json['version'] as int? ?? 0,
        nombre: json['nombre'] as String? ?? '',
        tipo: json['tipo'] as String? ?? '',
        profileId: json['profileId'] as int?,
      );

  @override
  Map<String, dynamic> toFirestore() {
    final map = super.toFirestore();
    map.addAll({'nombre': nombre, 'tipo': tipo, 'profileId': profileId});
    return map;
  }

  factory CategoryModel.fromEntity(Category category) => CategoryModel(
    id: category.id,
    createdAt: category.createdAt,
    updatedAt: category.updatedAt,
    deletedAt: category.deletedAt,
    deviceId: category.deviceId,
    version: category.version,
    syncStatus: category.syncStatus,
    nombre: category.nombre,
    tipo: category.tipo,
    profileId: category.profileId,
  );

  Category toEntity() => Category(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    deviceId: deviceId,
    version: version,
    syncStatus: syncStatus,
    nombre: nombre,
    tipo: tipo,
    profileId: profileId,
  );

  @override
  Map<String, dynamic> toJson() => toFirestore();

  @override
  List<Object?> get props => [...super.props, nombre, tipo, profileId];
}
