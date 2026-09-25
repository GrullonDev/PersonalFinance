import 'package:equatable/equatable.dart';
import 'package:personal_finance/core/constants/enums.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String userId;
  final TransactionType type; // income | expense
  final double amount;
  final String note;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus; // pending | synced | failed
  final int version;
  final String deviceId;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.version,
    required this.deviceId,
    this.categoryId,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    amount,
    note,
    categoryId,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    version,
    deviceId,
  ];
}
