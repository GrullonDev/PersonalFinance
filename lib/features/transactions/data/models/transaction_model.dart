import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:personal_finance/features/transactions/domain/entities/transaction.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
class TransactionModel extends Equatable {
  final String id;
  final String accountId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String type; // 'income' or 'expense'

  const TransactionModel({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.type,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  factory TransactionModel.fromEntity(Transaction transaction) =>
      TransactionModel(
        id: transaction.id,
        accountId: transaction.accountId,
        amount: transaction.amount,
        category: transaction.category,
        description: transaction.description,
        date: transaction.date,
        type: transaction.type,
      );

  Transaction toEntity() => Transaction(
    id: id,
    accountId: accountId,
    amount: amount,
    category: category,
    description: description,
    date: date,
    type: type,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    accountId,
    amount,
    category,
    description,
    date,
    type,
  ];
}
