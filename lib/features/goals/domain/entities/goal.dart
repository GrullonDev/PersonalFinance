import 'package:equatable/equatable.dart';

class Goal extends Equatable {
  final String? id;
  final String nombre;
  final String montoObjetivo;
  final String montoActual;
  final DateTime fechaLimite;
  final String? icono;
  final String? profileId;

  const Goal({
    required this.nombre,
    required this.montoObjetivo,
    required this.montoActual,
    required this.fechaLimite,
    this.id,
    this.icono,
    this.profileId,
  });

  Goal copyWith({
    String? id,
    String? nombre,
    String? montoObjetivo,
    String? montoActual,
    DateTime? fechaLimite,
    String? icono,
    String? profileId,
  }) => Goal(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    montoObjetivo: montoObjetivo ?? this.montoObjetivo,
    montoActual: montoActual ?? this.montoActual,
    fechaLimite: fechaLimite ?? this.fechaLimite,
    icono: icono ?? this.icono,
    profileId: profileId ?? this.profileId,
  );

  double get objetivoAsDouble => double.tryParse(montoObjetivo) ?? 0.0;
  double get actualAsDouble => double.tryParse(montoActual) ?? 0.0;

  @override
  List<Object?> get props => <Object?>[
    id,
    nombre,
    montoObjetivo,
    montoActual,
    fechaLimite,
    icono,
    profileId,
  ];
}
