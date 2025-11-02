import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String accountId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String type; // 'income' or 'expense'

  const Transaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.type,
  });

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
