import 'package:dartz/dartz.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_item.dart';

abstract class NotificationInboxRepository {
  Future<Either<Failure, List<NotificationItem>>> getNotifications();
  Future<Either<Failure, void>> saveNotification(NotificationItem notification);
  Future<Either<Failure, void>> markAsRead(String notificationId);
  Future<Either<Failure, void>> clearAll();
}
