import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final int? id;
  final String nombre;
  final String tipo; // 'ingreso' | 'egreso'
  final int? profileId;

  const CategoryModel({
    required this.nombre,
    required this.tipo,
    this.id,
    this.profileId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id:
        json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id']?.toString() ?? ''),
    nombre: json['nombre']?.toString() ?? '',
    tipo: json['tipo']?.toString() ?? '',
    profileId:
        json['profile_id'] is int
            ? json['profile_id'] as int
            : int.tryParse(json['profile_id']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'nombre': nombre,
    'tipo': tipo,
    if (profileId != null) 'profile_id': profileId,
  };

  @override
  List<Object?> get props => <Object?>[id, nombre, tipo, profileId];
}
