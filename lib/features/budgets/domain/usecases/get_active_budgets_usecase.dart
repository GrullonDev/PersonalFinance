import 'package:dartz/dartz.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';
import 'package:personal_finance/features/budgets/domain/repositories/budget_repository.dart';

class GetActiveBudgetsUseCase {
  final BudgetRepository repository;

  GetActiveBudgetsUseCase(this.repository);

  Future<Either<Failure, List<Budget>>> execute() async {
    return await repository.getBudgets();
  }
}
