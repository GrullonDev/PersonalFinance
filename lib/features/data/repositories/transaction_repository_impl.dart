import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
import 'package:personal_finance/features/domain/repositories/transaction_repository.dart';
import 'package:personal_finance/features/transactions/data/datasources/transaction_backend_remote_data_source.dart';
import 'package:personal_finance/features/transactions/data/models/transaction_backend_model.dart';

/// Implementación del repositorio de transacciones usando Firestore
/// Reemplaza la implementación anterior con Hive
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionBackendRemoteDataSource _remoteDataSource;

  TransactionRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ExpenseEntity>> getExpenses() async {
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'gasto');
      return transactions
          .map((TransactionBackendModel tx) => _mapModelToExpense(tx))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener gastos: $e');
    }
  }

  @override
  Future<List<IncomeEntity>> getIncomes() async {
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'ingreso');
      return transactions
          .map((TransactionBackendModel tx) => _mapModelToIncome(tx))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener ingresos: $e');
    }
  }

  @override
  Future<void> addExpense(ExpenseEntity expense) async {
    try {
      await _remoteDataSource.create(
        TransactionBackendModel(
          tipo: 'gasto',
          monto: expense.amount.toString(),
          descripcion: expense.title,
          fecha: expense.date,
          categoriaId: expense.category,
          esRecurrente: false, // Default value as Entity doesn't have it
        ),
      );
    } catch (e) {
      throw Exception('Error al agregar gasto: $e');
    }
  }

  @override
  Future<void> addIncome(IncomeEntity income) async {
    try {
      await _remoteDataSource.create(
        TransactionBackendModel(
          tipo: 'ingreso',
          monto: income.amount.toString(),
          descripcion: income.title,
          fecha: income.date,
          categoriaId: '0', // Default category for income if not present
          esRecurrente: false,
        ),
      );
    } catch (e) {
      throw Exception('Error al agregar ingreso: $e');
    }
  }

  @override
  Future<void> updateExpense(ExpenseEntity expense) async {
    try {
      await _remoteDataSource.update(
        expense.id,
        TransactionBackendModel(
          id: expense.id,
          tipo: 'gasto',
          monto: expense.amount.toString(),
          descripcion: expense.title,
          fecha: expense.date,
          categoriaId: expense.category,
          esRecurrente: false,
        ),
      );
    } catch (e) {
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  @override
  Future<void> updateIncome(IncomeEntity income) async {
    try {
      await _remoteDataSource.update(
        income.id,
        TransactionBackendModel(
          id: income.id,
          tipo: 'ingreso',
          monto: income.amount.toString(),
          descripcion: income.title,
          fecha: income.date,
          categoriaId: '0',
          esRecurrente: false,
        ),
      );
    } catch (e) {
      throw Exception('Error al actualizar ingreso: $e');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await _remoteDataSource.delete(id);
    } catch (e) {
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    try {
      await _remoteDataSource.delete(id);
    } catch (e) {
      throw Exception('Error al eliminar ingreso: $e');
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'gasto', fechaDesde: start, fechaHasta: end);
      return transactions
          .map((TransactionBackendModel tx) => _mapModelToExpense(tx))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener gastos por período: $e');
    }
  }

  @override
  Future<List<IncomeEntity>> getIncomesByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'ingreso', fechaDesde: start, fechaHasta: end);
      return transactions
          .map((TransactionBackendModel tx) => _mapModelToIncome(tx))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener ingresos por período: $e');
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByCategory(String category) async {
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'gasto', categoriaId: category);
      return transactions
          .map((TransactionBackendModel tx) => _mapModelToExpense(tx))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener gastos por categoría: $e');
    }
  }

  @override
  Future<List<IncomeEntity>> getIncomesBySource(String source) async {
    // This is less efficient with current list implementation as usage of 'source'
    // in TransactionBackendModel is ambiguous (likely mapped to description or not fully supported in filter)
    // Assuming source is stored in description for now or doing client-side filtering
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'ingreso');
      return transactions
          .where(
            (TransactionBackendModel tx) =>
                tx.descripcion.toLowerCase().contains(source.toLowerCase()),
          )
          .map((TransactionBackendModel tx) => _mapModelToIncome(tx))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener ingresos por fuente: $e');
    }
  }

  @override
  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    try {
      final List<ExpenseEntity> expenses = await getExpensesByPeriod(
        start,
        end,
      );
      return expenses.fold<double>(
        0,
        (double sum, ExpenseEntity expense) => sum + expense.amount,
      );
    } catch (e) {
      throw Exception('Error al calcular total de gastos: $e');
    }
  }

  @override
  Future<double> getTotalIncomes(DateTime start, DateTime end) async {
    try {
      final List<IncomeEntity> incomes = await getIncomesByPeriod(start, end);
      return incomes.fold<double>(
        0,
        (double sum, IncomeEntity income) => sum + income.amount,
      );
    } catch (e) {
      throw Exception('Error al calcular total de ingresos: $e');
    }
  }

  @override
  Future<double> getBalance(DateTime start, DateTime end) async {
    try {
      final double totalIncomes = await getTotalIncomes(start, end);
      final double totalExpenses = await getTotalExpenses(start, end);
      return totalIncomes - totalExpenses;
    } catch (e) {
      throw Exception('Error al calcular balance: $e');
    }
  }

  // Métodos de mapeo
  ExpenseEntity _mapModelToExpense(TransactionBackendModel model) =>
      ExpenseEntity(
        id: model.id ?? '',
        title: model.descripcion,
        amount: model.montoAsDouble,
        date: model.fecha,
        category: model.categoriaId,
      );

  IncomeEntity _mapModelToIncome(TransactionBackendModel model) => IncomeEntity(
    id: model.id ?? '',
    title: model.descripcion,
    amount: model.montoAsDouble,
    date: model.fecha,
    source: model.descripcion, // Using description as source
  );
}
