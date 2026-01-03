import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:personal_finance/features/profile/data/models/profile_me_model.dart';
import 'package:personal_finance/features/profile/domain/entities/profile_info.dart';
import 'package:personal_finance/features/profile/domain/repositories/profile_backend_repository.dart';

class ProfileBackendRepositoryImpl implements ProfileBackendRepository {
  ProfileBackendRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, ProfileInfo>> getMe() async {
    try {
      final ProfileMeModel model = await _remote.getMe();
      return right(
        ProfileInfo(
          fullName: model.fullName,
          email: model.email,
          photoUrl: model.photoUrl,
          firstName: model.firstName,
          lastName: model.lastName,
          username: model.username,
          phoneNumber: model.phoneNumber,
          address: model.address,
        ),
      );
    } on ApiException catch (e) {
      return left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile(ProfileInfo profile) async {
    try {
      final ProfileMeModel model = ProfileMeModel(
        fullName: profile.fullName,
        email: profile.email,
        photoUrl: profile.photoUrl,
        firstName: profile.firstName,
        lastName: profile.lastName,
        username: profile.username,
        phoneNumber: profile.phoneNumber,
        address: profile.address,
      );
      await _remote.updateMe(model);
      return right(null);
    } on ApiException catch (e) {
      return left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}
