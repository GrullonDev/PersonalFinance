import 'package:personal_finance/core/domain/entities/syncable_entity.dart';

class Transaction extends SyncableEntity {
  final String accountId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String type; // 'income' or 'expense'

  const Transaction({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deviceId,
    required super.version,
    required this.accountId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.type,
    super.deletedAt,
    super.syncStatus,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    accountId,
    amount,
    category,
    description,
    date,
    type,
  ];
}
