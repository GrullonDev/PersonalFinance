import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
import 'package:personal_finance/features/domain/repositories/transaction_repository.dart';

/// Parámetros para agregar un gasto
class AddExpenseParams {
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? description;
  final String? notes;

  const AddExpenseParams({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.description,
    this.notes,
  });
}

/// Parámetros para agregar un ingreso
class AddIncomeParams {
  final String title;
  final double amount;
  final DateTime date;
  final String source;
  final String? description;
  final String? notes;

  const AddIncomeParams({
    required this.title,
    required this.amount,
    required this.date,
    required this.source,
    this.description,
    this.notes,
  });
}

/// Caso de uso para agregar transacciones
class AddTransactionUseCase {
  final TransactionRepository repository;

  const AddTransactionUseCase(this.repository);

  /// Agrega un nuevo gasto
  Future<void> addExpense(AddExpenseParams params) async {
    try {
      // Validaciones
      if (params.title.isEmpty) {
        throw Exception('El título del gasto no puede estar vacío');
      }
      if (params.amount <= 0) {
        throw Exception('El monto del gasto debe ser mayor a 0');
      }
      if (params.category.isEmpty) {
        throw Exception('La categoría del gasto no puede estar vacía');
      }

      final ExpenseEntity expense = ExpenseEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: params.title,
        amount: params.amount,
        date: params.date,
        category: params.category,
        description: params.description,
        notes: params.notes,
      );

      await repository.addExpense(expense);
    } catch (e) {
      throw Exception('Error al agregar gasto: $e');
    }
  }

  /// Agrega un nuevo ingreso
  Future<void> addIncome(AddIncomeParams params) async {
    try {
      // Validaciones
      if (params.title.isEmpty) {
        throw Exception('El título del ingreso no puede estar vacío');
      }
      if (params.amount <= 0) {
        throw Exception('El monto del ingreso debe ser mayor a 0');
      }
      if (params.source.isEmpty) {
        throw Exception('La fuente del ingreso no puede estar vacía');
      }

      final IncomeEntity income = IncomeEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: params.title,
        amount: params.amount,
        date: params.date,
        source: params.source,
        description: params.description,
        notes: params.notes,
      );

      await repository.addIncome(income);
    } catch (e) {
      throw Exception('Error al agregar ingreso: $e');
    }
  }
}
