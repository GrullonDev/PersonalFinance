import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:personal_finance/features/profile/domain/entities/profile_info.dart';
import 'package:personal_finance/features/profile/domain/repositories/profile_backend_repository.dart';

class ProfileBackendRepositoryImpl implements ProfileBackendRepository {
  ProfileBackendRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, ProfileInfo>> getMe() async {
    try {
      final model = await _remote.getMe();
      return right(ProfileInfo(fullName: model.fullName, email: model.email));
    } on ApiException catch (e) {
      return left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}

