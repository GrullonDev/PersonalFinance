import 'package:hive_flutter/hive_flutter.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
import 'package:personal_finance/features/domain/repositories/transaction_repository.dart';

/// Implementación concreta del repositorio de transacciones usando Hive
class TransactionRepositoryImpl implements TransactionRepository {
  final Box<Expense> _expenseBox;
  final Box<Income> _incomeBox;

  TransactionRepositoryImpl(this._expenseBox, this._incomeBox);

  @override
  Future<List<ExpenseEntity>> getExpenses() async {
    try {
      return _expenseBox.values.map((expense) => _mapExpenseToEntity(expense)).toList();
    } catch (e) {
      throw Exception('Error al obtener gastos: $e');
    }
  }

  @override
  Future<List<IncomeEntity>> getIncomes() async {
    try {
      return _incomeBox.values.map((income) => _mapIncomeToEntity(income)).toList();
    } catch (e) {
      throw Exception('Error al obtener ingresos: $e');
    }
  }

  @override
  Future<void> addExpense(ExpenseEntity expense) async {
    try {
      final Expense expenseModel = _mapEntityToExpense(expense);
      await _expenseBox.add(expenseModel);
    } catch (e) {
      throw Exception('Error al agregar gasto: $e');
    }
  }

  @override
  Future<void> addIncome(IncomeEntity income) async {
    try {
      final Income incomeModel = _mapEntityToIncome(income);
      await _incomeBox.add(incomeModel);
    } catch (e) {
      throw Exception('Error al agregar ingreso: $e');
    }
  }

  @override
  Future<void> updateExpense(ExpenseEntity expense) async {
    try {
      final int index = _expenseBox.values.toList().indexWhere((e) => e.title == expense.title);
      if (index != -1) {
        final Expense expenseModel = _mapEntityToExpense(expense);
        await _expenseBox.putAt(index, expenseModel);
      }
    } catch (e) {
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  @override
  Future<void> updateIncome(IncomeEntity income) async {
    try {
      final int index = _incomeBox.values.toList().indexWhere((i) => i.title == income.title);
      if (index != -1) {
        final Income incomeModel = _mapEntityToIncome(income);
        await _incomeBox.putAt(index, incomeModel);
      }
    } catch (e) {
      throw Exception('Error al actualizar ingreso: $e');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      final int index = _expenseBox.values.toList().indexWhere((e) => e.title == id);
      if (index != -1) {
        await _expenseBox.deleteAt(index);
      }
    } catch (e) {
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    try {
      final int index = _incomeBox.values.toList().indexWhere((i) => i.title == id);
      if (index != -1) {
        await _incomeBox.deleteAt(index);
      }
    } catch (e) {
      throw Exception('Error al eliminar ingreso: $e');
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByPeriod(DateTime start, DateTime end) async {
    try {
      return _expenseBox.values
          .where((expense) => expense.date.isAfter(start.subtract(const Duration(days: 1))) && 
                              expense.date.isBefore(end.add(const Duration(days: 1))))
          .map((expense) => _mapExpenseToEntity(expense))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener gastos por período: $e');
    }
  }

  @override
  Future<List<IncomeEntity>> getIncomesByPeriod(DateTime start, DateTime end) async {
    try {
      return _incomeBox.values
          .where((income) => income.date.isAfter(start.subtract(const Duration(days: 1))) && 
                            income.date.isBefore(end.add(const Duration(days: 1))))
          .map((income) => _mapIncomeToEntity(income))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener ingresos por período: $e');
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByCategory(String category) async {
    try {
      return _expenseBox.values
          .where((expense) => expense.category.toLowerCase() == category.toLowerCase())
          .map((expense) => _mapExpenseToEntity(expense))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener gastos por categoría: $e');
    }
  }

  @override
  Future<List<IncomeEntity>> getIncomesBySource(String source) async {
    try {
      return _incomeBox.values
          .where((income) => income.title.toLowerCase().contains(source.toLowerCase()))
          .map((income) => _mapIncomeToEntity(income))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener ingresos por fuente: $e');
    }
  }

  @override
  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    try {
      final List<ExpenseEntity> expenses = await getExpensesByPeriod(start, end);
      return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    } catch (e) {
      throw Exception('Error al calcular total de gastos: $e');
    }
  }

  @override
  Future<double> getTotalIncomes(DateTime start, DateTime end) async {
    try {
      final List<IncomeEntity> incomes = await getIncomesByPeriod(start, end);
      return incomes.fold<double>(0, (sum, income) => sum + income.amount);
    } catch (e) {
      throw Exception('Error al calcular total de ingresos: $e');
    }
  }

  @override
  Future<double> getBalance(DateTime start, DateTime end) async {
    try {
      final totalIncomes = await getTotalIncomes(start, end);
      final totalExpenses = await getTotalExpenses(start, end);
      return totalIncomes - totalExpenses;
    } catch (e) {
      throw Exception('Error al calcular balance: $e');
    }
  }

  // Métodos de mapeo entre entidades y modelos
  ExpenseEntity _mapExpenseToEntity(Expense expense) {
    return ExpenseEntity(
      id: expense.title, // Usando title como ID temporal
      title: expense.title,
      amount: expense.amount,
      date: expense.date,
      category: expense.category,
      description: null,
      notes: null,
    );
  }

  IncomeEntity _mapIncomeToEntity(Income income) {
    return IncomeEntity(
      id: income.title, // Usando title como ID temporal
      title: income.title,
      amount: income.amount,
      date: income.date,
      source: income.title, // Usando title como source temporal
      description: null,
      notes: null,
    );
  }

  Expense _mapEntityToExpense(ExpenseEntity entity) {
    return Expense(
      title: entity.title,
      amount: entity.amount,
      date: entity.date,
      category: entity.category,
    );
  }

  Income _mapEntityToIncome(IncomeEntity entity) {
    return Income(
      title: entity.title,
      amount: entity.amount,
      date: entity.date,
    );
  }
} 