import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';

abstract class GoalRepository {
  Future<Either<Failure, List<Goal>>> getGoals();
  Future<Either<Failure, Goal>> createGoal(Goal goal);
  Future<Either<Failure, Goal>> updateGoal(Goal goal);
  Future<Either<Failure, void>> deleteGoal(int id);
}
