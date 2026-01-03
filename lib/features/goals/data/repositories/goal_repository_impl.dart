import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/goals/data/datasources/goal_remote_data_source.dart';
import 'package:personal_finance/features/goals/data/models/goal_model.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl(this._remote);

  final GoalRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Goal>>> getGoals() async {
    try {
      final List<GoalModel> list = await _remote.getGoals();
      return Right(
        list
            .map(
              (GoalModel e) => Goal(
                id: e.id,
                nombre: e.nombre,
                montoObjetivo: e.montoObjetivo,
                montoActual: e.montoActual,
                fechaLimite: e.fechaLimite,
                icono: e.icono,
                profileId: e.profileId,
              ),
            )
            .toList(),
      );
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Goal>> createGoal(Goal goal) async {
    try {
      final GoalModel created = await _remote.createGoal(
        GoalModel(
          nombre: goal.nombre,
          montoObjetivo: goal.montoObjetivo,
          montoActual: goal.montoActual,
          fechaLimite: goal.fechaLimite,
          icono: goal.icono,
        ),
      );
      return Right(
        Goal(
          id: created.id,
          nombre: created.nombre,
          montoObjetivo: created.montoObjetivo,
          montoActual: created.montoActual,
          fechaLimite: created.fechaLimite,
          icono: created.icono,
          profileId: created.profileId,
        ),
      );
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Goal>> updateGoal(Goal goal) async {
    try {
      final GoalModel updated = await _remote.updateGoal(
        goal.id!,
        GoalModel(
          id: goal.id,
          nombre: goal.nombre,
          montoObjetivo: goal.montoObjetivo,
          montoActual: goal.montoActual,
          fechaLimite: goal.fechaLimite,
          icono: goal.icono,
        ),
      );
      return Right(
        Goal(
          id: updated.id,
          nombre: updated.nombre,
          montoObjetivo: updated.montoObjetivo,
          montoActual: updated.montoActual,
          fechaLimite: updated.fechaLimite,
          icono: updated.icono,
          profileId: updated.profileId,
        ),
      );
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGoal(String id) async {
    try {
      await _remote.deleteGoal(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
