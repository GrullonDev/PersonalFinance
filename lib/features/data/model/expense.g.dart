// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Expense(
      title:
          fields[0] as String? ??
          'Default Title', // Valor predeterminado si es null
      amount: fields[1] as double? ?? 0.0, // Valor predeterminado si es null
      date:
          fields[2] as DateTime? ??
          DateTime.now(), // Valor predeterminado si es null
      category:
          fields[3] as String? ?? 'Otros', // Valor predeterminado si es null
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title) // Asegúrate de que `obj.title` no sea null
      ..writeByte(1)
      ..write(obj.amount) // Asegúrate de que `obj.amount` no sea null
      ..writeByte(2)
      ..write(obj.date) // Asegúrate de que `obj.date` no sea null
      ..writeByte(3)
      ..write(obj.category); // Asegúrate de que `obj.category` no sea null
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
