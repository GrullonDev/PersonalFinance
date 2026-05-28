import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/budgets/data/datasources/budget_remote_data_source.dart';
import 'package:personal_finance/features/budgets/data/models/budget_model.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';
import 'package:personal_finance/features/budgets/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._remote);

  final BudgetRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Budget>>> getBudgets() async {
    try {
      final List<BudgetModel> list = await _remote.getBudgets();
      return Right(list.map((BudgetModel e) => e.toEntity()).toList());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Budget>> createBudget(Budget budget) async {
    try {
      final BudgetModel created = await _remote.createBudget(
        BudgetModel.fromEntity(budget),
      );
      return Right(created.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Budget>> updateBudget(Budget budget) async {
    try {
      final BudgetModel updated = await _remote.updateBudget(
        budget.id,
        BudgetModel.fromEntity(budget),
      );
      return Right(updated.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBudget(String id) async {
    try {
      await _remote.deleteBudget(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
