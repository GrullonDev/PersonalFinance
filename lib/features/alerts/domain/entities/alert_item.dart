import 'package:hive/hive.dart';

part 'alert_item.g.dart';

@HiveType(typeId: 2)
class AlertItem {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final DateTime date;

  AlertItem({
    required this.title,
    required this.description,
    required this.date,
  });
}
