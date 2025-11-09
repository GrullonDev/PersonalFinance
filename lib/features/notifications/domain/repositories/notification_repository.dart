import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_preferences.dart';

abstract class NotificationRepository {
  Future<Either<Failure, NotificationPreferences>> getPreferences();
  Future<Either<Failure, NotificationPreferences>> updatePreferences(
    NotificationPreferences prefs,
  );
}
