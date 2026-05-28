import 'package:personal_finance/core/data/models/syncable_model.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction.dart';

class TransactionModel extends SyncableModel {
  final String accountId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String type; // 'income' or 'expense'

  const TransactionModel({
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

  factory TransactionModel.fromFirestore(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        createdAt: dateTimeFromTimestamp(json['createdAt']),
        updatedAt: dateTimeFromTimestamp(json['updatedAt']),
        deletedAt:
            json['deletedAt'] != null
                ? dateTimeFromTimestamp(json['deletedAt'])
                : null,
        deviceId: json['deviceId'] as String? ?? '',
        version: json['version'] as int? ?? 0,
        accountId: json['accountId'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        description: json['description'] as String,
        date: dateTimeFromTimestamp(json['date']),
        type: json['type'] as String,
      );

  @override
  Map<String, dynamic> toFirestore() {
    final map = super.toFirestore();
    map.addAll({
      'accountId': accountId,
      'amount': amount,
      'category': category,
      'description': description,
      'date': timestampFromDateTime(date),
      'type': type,
    });
    return map;
  }

  factory TransactionModel.fromEntity(Transaction transaction) =>
      TransactionModel(
        id: transaction.id,
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
        deletedAt: transaction.deletedAt,
        deviceId: transaction.deviceId,
        version: transaction.version,
        syncStatus: transaction.syncStatus,
        accountId: transaction.accountId,
        amount: transaction.amount,
        category: transaction.category,
        description: transaction.description,
        date: transaction.date,
        type: transaction.type,
      );

  Transaction toEntity() => Transaction(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    deviceId: deviceId,
    version: version,
    syncStatus: syncStatus,
    accountId: accountId,
    amount: amount,
    category: category,
    description: description,
    date: date,
    type: type,
  );

  @override
  Map<String, dynamic> toJson() => toFirestore();

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
