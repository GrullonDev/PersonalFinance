// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_item.dart';

// ***************************************************************************
// TypeAdapterGenerator
// ***************************************************************************

class AlertItemAdapter extends TypeAdapter<AlertItem> {
  @override
  final int typeId = 2;

  @override
  AlertItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertItem(
      title: fields[0] as String,
      description: fields[1] as String,
      date: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AlertItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
