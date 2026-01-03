import 'package:equatable/equatable.dart';

class TransactionBackend extends Equatable {
  final String? id;
  final String tipo; // ingreso | gasto
  final String monto; // string
  final String descripcion;
  final DateTime fecha;
  final String categoriaId;
  final bool esRecurrente;
  final int? profileId;

  const TransactionBackend({
    required this.tipo,
    required this.monto,
    required this.descripcion,
    required this.fecha,
    required this.categoriaId,
    required this.esRecurrente,
    this.id,
    this.profileId,
  });

  TransactionBackend copyWith({
    String? id,
    String? tipo,
    String? monto,
    String? descripcion,
    DateTime? fecha,
    String? categoriaId,
    bool? esRecurrente,
    int? profileId,
  }) => TransactionBackend(
    id: id ?? this.id,
    tipo: tipo ?? this.tipo,
    monto: monto ?? this.monto,
    descripcion: descripcion ?? this.descripcion,
    fecha: fecha ?? this.fecha,
    categoriaId: categoriaId ?? this.categoriaId,
    esRecurrente: esRecurrente ?? this.esRecurrente,
    profileId: profileId ?? this.profileId,
  );

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
