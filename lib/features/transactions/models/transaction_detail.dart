import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';

class TransactionDivision {
  final String category;
  final double amount;
  final String? description;

  const TransactionDivision({
    required this.category,
    required this.amount,
    this.description,
  });
}

class TransactionDetail {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final bool isExpense;
  final String? notes;
  final String? receiptImagePath;
  final List<TransactionDivision> divisions;

  TransactionDetail({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isExpense,
    this.notes,
    this.receiptImagePath,
    this.divisions = const <TransactionDivision>[],
  });

  factory TransactionDetail.fromExpense(
    Expense expense, {
    String? id,
    String? notes,
    String? receiptImagePath,
    List<TransactionDivision> divisions = const <TransactionDivision>[],
  }) => TransactionDetail(
    id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: expense.title,
    amount: expense.amount,
    date: expense.date,
    category: expense.category,
    isExpense: true,
    notes: notes,
    receiptImagePath: receiptImagePath,
    divisions: divisions,
  );

  factory TransactionDetail.fromIncome(
    Income income, {
    String? id,
    String? notes,
    List<TransactionDivision> divisions = const <TransactionDivision>[],
  }) => TransactionDetail(
    id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: income.title,
    amount: income.amount,
    date: income.date,
    category: 'Ingreso',
    isExpense: false,
    notes: notes,
    divisions: divisions,
  );
}
