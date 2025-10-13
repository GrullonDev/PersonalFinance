import 'package:flutter/foundation.dart';

enum TransactionType { expense, income }

@immutable
class TransactionModel {
  const TransactionModel({
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
    this.isRecurring = false,
  });

  final TransactionType type;
  final double amount;
  final String category;
  final DateTime date;
  final String? description;
  final bool isRecurring;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.toString(),
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'description': description,
    'isRecurring': isRecurring,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        type:
            json['type'] == 'TransactionType.expense'
                ? TransactionType.expense
                : TransactionType.income,
        amount: json['amount'] as double,
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String?,
        isRecurring: json['isRecurring'] as bool? ?? false,
      );

  TransactionModel copyWith({
    TransactionType? type,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
    bool? isRecurring,
  }) => TransactionModel(
    type: type ?? this.type,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    date: date ?? this.date,
    description: description ?? this.description,
    isRecurring: isRecurring ?? this.isRecurring,
  );
}
