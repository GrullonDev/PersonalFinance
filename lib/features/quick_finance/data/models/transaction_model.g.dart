// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 3;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as TransactionType,
      amount: fields[3] as double,
      note: fields[4] as String,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      deletedAt: fields[7] as DateTime?,
      syncStatus: fields[8] as SyncStatus,
      version: fields[9] as int,
      deviceId: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.deletedAt)
      ..writeByte(8)
      ..write(obj.syncStatus)
      ..writeByte(9)
      ..write(obj.version)
      ..writeByte(10)
      ..write(obj.deviceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      syncStatus: $enumDecode(_$SyncStatusEnumMap, json['syncStatus']),
      version: (json['version'] as num).toInt(),
      deviceId: json['deviceId'] as String,
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
      'version': instance.version,
      'deviceId': instance.deviceId,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
};

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'pending',
  SyncStatus.synced: 'synced',
  SyncStatus.failed: 'failed',
};
