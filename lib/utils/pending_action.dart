import 'package:hive/hive.dart';

part 'pending_action.g.dart';

@HiveType(typeId: 0)
class PendingAction extends HiveObject {
  @HiveField(0)
  String type; // 'create', 'update', 'delete'

  @HiveField(1)
  Map<String, dynamic> data;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  String status; // 'pending', 'sent', 'error'

  PendingAction({
    required this.type,
    required this.data,
    required this.timestamp,
    this.status = 'pending',
  });
}
