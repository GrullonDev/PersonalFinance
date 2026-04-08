import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:personal_finance/core/constants/enums.dart';
import '../../domain/entities/transaction_entity.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 3)
class TransactionModel extends TransactionEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String userId;

  @HiveField(2)
  @override
  final TransactionType type;

  @HiveField(3)
  @override
  final double amount;

  @HiveField(4)
  @override
  final String note;

  @HiveField(5)
  @override
  final DateTime createdAt;

  @HiveField(6)
  @override
  final DateTime updatedAt;

  @HiveField(7)
  @override
  final DateTime? deletedAt;

  @HiveField(8)
  @override
  final SyncStatus syncStatus;

  @HiveField(9)
  @override
  final int version;

  @HiveField(10)
  @override
  final String deviceId;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.version,
    required this.deviceId,
  }) : super(
          id: id,
          userId: userId,
          type: type,
          amount: amount,
          note: note,
          createdAt: createdAt,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
          syncStatus: syncStatus,
          version: version,
          deviceId: deviceId,
        );

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      amount: entity.amount,
      note: entity.note,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      syncStatus: entity.syncStatus,
      version: entity.version,
      deviceId: entity.deviceId,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
    int? version,
    String? deviceId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
