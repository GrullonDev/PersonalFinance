import 'package:hive/hive.dart';

part 'enums.g.dart';

/// Tipo de transacción
@HiveType(typeId: 0)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense
}

/// Estado de sincronización para operaciones locales/remotas
@HiveType(typeId: 1)
enum SyncStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  synced,
  @HiveField(2)
  failed
}

/// Acción a realizar durante una sincronización
@HiveType(typeId: 2)
enum SyncAction {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete
}
