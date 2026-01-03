import 'package:dartz/dartz.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';

class GetActiveGoalsUseCase {
  final GoalRepository repository;

  GetActiveGoalsUseCase(this.repository);

  Future<Either<Failure, List<Goal>>> execute() async {
    return await repository.getGoals();
  }
}
