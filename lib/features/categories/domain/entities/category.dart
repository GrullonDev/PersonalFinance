import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String? id;
  final String nombre;
  final String tipo; // 'ingreso' | 'egreso'
  final int? profileId;

  const Category({
    required this.nombre,
    required this.tipo,
    this.id,
    this.profileId,
  });

  Category copyWith({
    String? id,
    String? nombre,
    String? tipo,
    int? profileId,
  }) => Category(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    tipo: tipo ?? this.tipo,
    profileId: profileId ?? this.profileId,
  );

  @override
  List<Object?> get props => <Object?>[id, nombre, tipo, profileId];
}
