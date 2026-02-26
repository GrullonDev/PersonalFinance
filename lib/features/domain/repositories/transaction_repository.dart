import 'package:dartz/dartz.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';

/// Repositorio abstracto para manejar transacciones
/// Sigue el principio de inversión de dependencias (DIP)
abstract class TransactionRepository {
  /// Obtiene todos los gastos
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses();

  /// Obtiene todos los ingresos
  Future<Either<Failure, List<IncomeEntity>>> getIncomes();

  /// Agrega un nuevo gasto
  Future<Either<Failure, void>> addExpense(ExpenseEntity expense);

  /// Agrega un nuevo ingreso
  Future<Either<Failure, void>> addIncome(IncomeEntity income);

  /// Actualiza un gasto existente
  Future<Either<Failure, void>> updateExpense(ExpenseEntity expense);

  /// Actualiza un ingreso existente
  Future<Either<Failure, void>> updateIncome(IncomeEntity income);

  /// Elimina un gasto
  Future<Either<Failure, void>> deleteExpense(String id);

  /// Elimina un ingreso
  Future<Either<Failure, void>> deleteIncome(String id);

  /// Obtiene gastos filtrados por período
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesByPeriod(
    DateTime start,
    DateTime end,
  );

  /// Obtiene ingresos filtrados por período
  Future<Either<Failure, List<IncomeEntity>>> getIncomesByPeriod(
    DateTime start,
    DateTime end,
  );

  /// Obtiene gastos por categoría
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesByCategory(
    String category,
  );

  /// Obtiene ingresos por fuente
  Future<Either<Failure, List<IncomeEntity>>> getIncomesBySource(String source);

  /// Obtiene el total de gastos en un período
  Future<Either<Failure, double>> getTotalExpenses(
    DateTime start,
    DateTime end,
  );

  /// Obtiene el total de ingresos en un período
  Future<Either<Failure, double>> getTotalIncomes(DateTime start, DateTime end);

  /// Obtiene el balance en un período
  Future<Either<Failure, double>> getBalance(DateTime start, DateTime end);
}
