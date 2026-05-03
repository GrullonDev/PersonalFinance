// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_operation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncOperationModelAdapter extends TypeAdapter<SyncOperationModel> {
  @override
  final int typeId = 4;

  @override
  SyncOperationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncOperationModel(
      id: fields[0] as String,
      transactionId: fields[1] as String,
      action: fields[2] as SyncAction,
      createdAt: fields[3] as DateTime,
      processed: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperationModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.transactionId)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.processed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncOperationModel _$SyncOperationModelFromJson(Map<String, dynamic> json) =>
    SyncOperationModel(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      action: $enumDecode(_$SyncActionEnumMap, json['action']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      processed: json['processed'] as bool,
    );

Map<String, dynamic> _$SyncOperationModelToJson(SyncOperationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transactionId': instance.transactionId,
      'action': _$SyncActionEnumMap[instance.action]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'processed': instance.processed,
    };

const _$SyncActionEnumMap = {
  SyncAction.create: 'create',
  SyncAction.update: 'update',
  SyncAction.delete: 'delete',
};
