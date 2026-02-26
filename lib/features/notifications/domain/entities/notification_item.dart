import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'notification_item.g.dart';

@HiveType(typeId: 4) // Assuming next available typeId
class NotificationItem extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final bool isRead;

  @HiveField(5)
  final String? type; // 'alert', 'reminder', 'budget', etc.

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    String? type,
  }) => NotificationItem(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    timestamp: timestamp ?? this.timestamp,
    isRead: isRead ?? this.isRead,
    type: type ?? this.type,
  );

  @override
  List<Object?> get props => [id, title, body, timestamp, isRead, type];
}
