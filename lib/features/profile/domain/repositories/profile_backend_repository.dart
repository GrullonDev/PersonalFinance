import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/profile/domain/entities/profile_info.dart';

abstract class ProfileBackendRepository {
  Future<Either<Failure, ProfileInfo>> getMe();
}

