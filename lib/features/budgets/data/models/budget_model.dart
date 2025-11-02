import 'package:equatable/equatable.dart';

class BudgetModel extends Equatable {
  final int? id;
  final String nombre;
  final String montoTotal; // keep as string to avoid precision issues
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int? profileId;

  const BudgetModel({
    required this.nombre,
    required this.montoTotal,
    required this.fechaInicio,
    required this.fechaFin,
    this.id,
    this.profileId,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
    id:
        json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id']?.toString() ?? ''),
    nombre: json['nombre']?.toString() ?? '',
    montoTotal: json['monto_total']?.toString() ?? '0',
    fechaInicio:
        DateTime.tryParse(json['fecha_inicio']?.toString() ?? '') ??
        DateTime.now(),
    fechaFin:
        DateTime.tryParse(json['fecha_fin']?.toString() ?? '') ??
        DateTime.now(),
    profileId:
        json['profile_id'] is int
            ? json['profile_id'] as int
            : int.tryParse(json['profile_id']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'nombre': nombre,
    'monto_total': double.tryParse(montoTotal) ?? montoTotal,
    'fecha_inicio': _formatDate(fechaInicio),
    'fecha_fin': _formatDate(fechaFin),
    if (profileId != null) 'profile_id': profileId,
  };

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
