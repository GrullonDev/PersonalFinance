import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:equatable/equatable.dart';

part 'sync_operation_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 4)
class SyncOperationModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String transactionId;
  @HiveField(2)
  final SyncAction action; // create | update | delete
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final bool processed;

  const SyncOperationModel({
    required this.id,
    required this.transactionId,
    required this.action,
    required this.createdAt,
    required this.processed,
  });

  @override
  List<Object?> get props => [id, transactionId, action, createdAt, processed];

  SyncOperationModel copyWith({
    String? id,
    String? transactionId,
    SyncAction? action,
    DateTime? createdAt,
    bool? processed,
  }) =>
      SyncOperationModel(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        action: action ?? this.action,
        createdAt: createdAt ?? this.createdAt,
        processed: processed ?? this.processed,
      );

  factory SyncOperationModel.fromJson(Map<String, dynamic> json) =>
      _$SyncOperationModelFromJson(json);

  Map<String, dynamic> toJson() => _$SyncOperationModelToJson(this);
}
