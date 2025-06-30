import 'package:hive/hive.dart';

part 'income.g.dart'; // Asegúrate de que esta línea está correctamente escrita

@HiveType(typeId: 1)
class Income {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  Income({required this.title, required this.amount, required this.date});
}
