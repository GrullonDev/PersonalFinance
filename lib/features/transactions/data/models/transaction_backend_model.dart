import 'package:equatable/equatable.dart';

class TransactionBackendModel extends Equatable {
  final String? id;
  final String tipo; // ingreso | gasto
  final String monto; // keep string to preserve precision
  final String descripcion;
  final DateTime fecha;
  final String categoriaId;
  final bool esRecurrente;
  final int? profileId;

  const TransactionBackendModel({
    required this.tipo,
    required this.monto,
    required this.descripcion,
    required this.fecha,
    required this.categoriaId,
    required this.esRecurrente,
    this.id,
    this.profileId,
  });

  factory TransactionBackendModel.fromJson(
    Map<String, dynamic> json,
  ) => TransactionBackendModel(
    id: json['id']?.toString(),
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

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'tipo': tipo,
    'monto': double.tryParse(monto) ?? monto,
    'descripcion': descripcion,
    'fecha': _fmt(fecha),
    'categoria_id': categoriaId,
    'es_recurrente': esRecurrente,
    if (profileId != null) 'profile_id': profileId,
  };

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  double get montoAsDouble => double.tryParse(monto) ?? 0.0;

  @override
  List<Object?> get props => <Object?>[
    id,
    tipo,
    monto,
    descripcion,
    fecha,
    categoriaId,
    esRecurrente,
    profileId,
  ];
}
