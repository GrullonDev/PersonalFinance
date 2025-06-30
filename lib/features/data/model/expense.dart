import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense {
  @HiveField(0)
  final String title; // Asegúrate de que este campo no puede ser null

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String category; // Asegúrate de que este campo no puede ser null

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });
}
