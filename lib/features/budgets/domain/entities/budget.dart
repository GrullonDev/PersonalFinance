import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final int? id;
  final String nombre;
  final String montoTotal; // keep as string
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int? profileId;

  const Budget({
    required this.nombre,
    required this.montoTotal,
    required this.fechaInicio,
    required this.fechaFin,
    this.id,
    this.profileId,
  });

  Budget copyWith({
    int? id,
    String? nombre,
    String? montoTotal,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? profileId,
  }) => Budget(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    montoTotal: montoTotal ?? this.montoTotal,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    profileId: profileId ?? this.profileId,
  );

  double get montoAsDouble => double.tryParse(montoTotal) ?? 0.0;

  @override
  List<Object?> get props => <Object?>[
    id,
    nombre,
    montoTotal,
    fechaInicio,
    fechaFin,
    profileId,
  ];
}
