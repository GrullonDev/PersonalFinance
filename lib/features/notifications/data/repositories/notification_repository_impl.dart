import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:personal_finance/features/notifications/data/models/notification_preferences_model.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_preferences.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Future<Either<Failure, NotificationPreferences>> getPreferences() async {
    try {
      final NotificationPreferencesModel m = await _remote.getPreferences();
      return Right(
        NotificationPreferences(
          emailEnabled: m.emailEnabled,
          pushEnabled: m.pushEnabled,
          marketingEnabled: m.marketingEnabled,
        ),
      );
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferences>> updatePreferences(
    NotificationPreferences prefs,
  ) async {
    try {
      final NotificationPreferencesModel m = await _remote.updatePreferences(
        NotificationPreferencesModel(
          emailEnabled: prefs.emailEnabled,
          pushEnabled: prefs.pushEnabled,
          marketingEnabled: prefs.marketingEnabled,
        ),
      );
      return Right(
        NotificationPreferences(
          emailEnabled: m.emailEnabled,
          pushEnabled: m.pushEnabled,
          marketingEnabled: m.marketingEnabled,
        ),
      );
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
