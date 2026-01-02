import 'package:equatable/equatable.dart';

class GoalModel extends Equatable {
  final String? id;
  final String nombre;
  final String montoObjetivo; // keep strings for precision
  final String montoActual;
  final DateTime fechaLimite;
  final String? icono;
  final String? profileId;

  const GoalModel({
    required this.nombre,
    required this.montoObjetivo,
    required this.montoActual,
    required this.fechaLimite,
    this.id,
    this.icono,
    this.profileId,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
    id: json['id']?.toString(),
    nombre: json['nombre']?.toString() ?? '',
    montoObjetivo: json['monto_objetivo']?.toString() ?? '0',
    montoActual: json['monto_actual']?.toString() ?? '0',
    fechaLimite:
        DateTime.tryParse(json['fecha_limite']?.toString() ?? '') ??
        DateTime.now(),
    icono: json['icono']?.toString(),
    profileId: json['profile_id']?.toString(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'nombre': nombre,
    'monto_objetivo': double.tryParse(montoObjetivo) ?? montoObjetivo,
    'monto_actual': double.tryParse(montoActual) ?? montoActual,
    'fecha_limite': _fmt(fechaLimite),
    if (icono != null) 'icono': icono,
    if (profileId != null) 'profile_id': profileId,
  };

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
