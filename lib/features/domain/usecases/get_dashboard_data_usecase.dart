import 'package:dartz/dartz.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
import 'package:personal_finance/features/domain/repositories/transaction_repository.dart';

/// Parámetros para obtener datos del dashboard
class DashboardParams {
  final DateTime startDate;
  final DateTime endDate;

  const DashboardParams({required this.startDate, required this.endDate});
}

/// Resultado del dashboard
class DashboardResult {
  final List<ExpenseEntity> expenses;
  final List<IncomeEntity> incomes;
  final double totalExpenses;
  final double totalIncomes;
  final double balance;

  const DashboardResult({
    required this.expenses,
    required this.incomes,
    required this.totalExpenses,
    required this.totalIncomes,
    required this.balance,
  });
}

/// Caso de uso para obtener datos del dashboard
/// Sigue el principio de responsabilidad única (SRP)
class GetDashboardDataUseCase {
  final TransactionRepository repository;

  const GetDashboardDataUseCase(this.repository);

  /// Ejecuta el caso de uso
  Future<Either<Failure, DashboardResult>> execute(
    DashboardParams params,
  ) async {
    try {
      final resExpenses = await repository.getExpensesByPeriod(
        params.startDate,
        params.endDate,
      );
      final resIncomes = await repository.getIncomesByPeriod(
        params.startDate,
        params.endDate,
      );

      return resExpenses.fold(
        (Failure l) => Left(l),
        (List<ExpenseEntity> expenses) => resIncomes.fold(
          (Failure l) => Left(l),
          (List<IncomeEntity> incomes) {
            // Calcular totales
            final double totalExpenses = expenses.fold(
              0,
              (double sum, ExpenseEntity expense) => sum + expense.amount,
            );
            final double totalIncomes = incomes.fold(
              0,
              (double sum, IncomeEntity income) => sum + income.amount,
            );
            final double balance = totalIncomes - totalExpenses;

            return Right(
              DashboardResult(
                expenses: expenses,
                incomes: incomes,
                totalExpenses: totalExpenses,
                totalIncomes: totalIncomes,
                balance: balance,
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Error en dashboard: $e'));
    }
  }
}
