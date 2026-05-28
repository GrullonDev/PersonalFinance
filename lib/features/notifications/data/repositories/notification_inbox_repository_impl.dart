import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_item.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_inbox_repository.dart';

class NotificationInboxRepositoryImpl implements NotificationInboxRepository {
  final Box<NotificationItem> _box;

  NotificationInboxRepositoryImpl(this._box);

  @override
  Future<Either<Failure, List<NotificationItem>>> getNotifications() async {
    try {
      final notifications =
          _box.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(notifications);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveNotification(
    NotificationItem notification,
  ) async {
    try {
      await _box.put(notification.id, notification);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      final notification = _box.get(notificationId);
      if (notification != null) {
        await _box.put(notificationId, notification.copyWith(isRead: true));
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    try {
      await _box.clear();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
