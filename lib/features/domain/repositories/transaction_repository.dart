import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';

/// Repositorio abstracto para manejar transacciones
/// Sigue el principio de inversión de dependencias (DIP)
abstract class TransactionRepository {
  /// Obtiene todos los gastos
  Future<List<ExpenseEntity>> getExpenses();

  /// Obtiene todos los ingresos
  Future<List<IncomeEntity>> getIncomes();

  /// Agrega un nuevo gasto
  Future<void> addExpense(ExpenseEntity expense);

  /// Agrega un nuevo ingreso
  Future<void> addIncome(IncomeEntity income);

  /// Actualiza un gasto existente
  Future<void> updateExpense(ExpenseEntity expense);

  /// Actualiza un ingreso existente
  Future<void> updateIncome(IncomeEntity income);

  /// Elimina un gasto
  Future<void> deleteExpense(String id);

  /// Elimina un ingreso
  Future<void> deleteIncome(String id);

  /// Obtiene gastos filtrados por período
  Future<List<ExpenseEntity>> getExpensesByPeriod(DateTime start, DateTime end);

  /// Obtiene ingresos filtrados por período
  Future<List<IncomeEntity>> getIncomesByPeriod(DateTime start, DateTime end);

  /// Obtiene gastos por categoría
  Future<List<ExpenseEntity>> getExpensesByCategory(String category);

  /// Obtiene ingresos por fuente
  Future<List<IncomeEntity>> getIncomesBySource(String source);

  /// Obtiene el total de gastos en un período
  Future<double> getTotalExpenses(DateTime start, DateTime end);

  /// Obtiene el total de ingresos en un período
  Future<double> getTotalIncomes(DateTime start, DateTime end);

  /// Obtiene el balance en un período
  Future<double> getBalance(DateTime start, DateTime end);
}
