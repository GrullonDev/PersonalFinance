import 'package:dartz/dartz.dart';
import 'package:personal_finance/core/error/failures.dart';
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
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses() async {
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'gasto');
      return Right(
        transactions
            .map((TransactionBackendModel tx) => _mapModelToExpense(tx))
            .toList(),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener gastos: $e'));
    }
  }

  @override
  Future<Either<Failure, List<IncomeEntity>>> getIncomes() async {
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'ingreso');
      return Right(
        transactions
            .map((TransactionBackendModel tx) => _mapModelToIncome(tx))
            .toList(),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener ingresos: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addExpense(ExpenseEntity expense) async {
    try {
      await _remoteDataSource.create(
        TransactionBackendModel(
          id: expense.id,
          createdAt: expense.createdAt,
          updatedAt: expense.updatedAt,
          deviceId: expense.deviceId,
          version: expense.version,
          syncStatus: expense.syncStatus,
          tipo: 'gasto',
          monto: expense.amount.toString(),
          descripcion: expense.title,
          fecha: expense.date,
          categoriaId: expense.category,
          esRecurrente: false,
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al agregar gasto: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addIncome(IncomeEntity income) async {
    try {
      await _remoteDataSource.create(
        TransactionBackendModel(
          id: income.id,
          createdAt: income.createdAt,
          updatedAt: income.updatedAt,
          deviceId: income.deviceId,
          version: income.version,
          syncStatus: income.syncStatus,
          tipo: 'ingreso',
          monto: income.amount.toString(),
          descripcion: income.title,
          fecha: income.date,
          categoriaId: '0',
          esRecurrente: false,
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al agregar ingreso: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateExpense(ExpenseEntity expense) async {
    try {
      await _remoteDataSource.update(
        expense.id,
        TransactionBackendModel(
          id: expense.id,
          createdAt: expense.createdAt,
          updatedAt: expense.updatedAt,
          deviceId: expense.deviceId,
          version: expense.version,
          syncStatus: expense.syncStatus,
          tipo: 'gasto',
          monto: expense.amount.toString(),
          descripcion: expense.title,
          fecha: expense.date,
          categoriaId: expense.category,
          esRecurrente: false,
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al actualizar gasto: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateIncome(IncomeEntity income) async {
    try {
      await _remoteDataSource.update(
        income.id,
        TransactionBackendModel(
          id: income.id,
          createdAt: income.createdAt,
          updatedAt: income.updatedAt,
          deviceId: income.deviceId,
          version: income.version,
          syncStatus: income.syncStatus,
          tipo: 'ingreso',
          monto: income.amount.toString(),
          descripcion: income.title,
          fecha: income.date,
          categoriaId: '0',
          esRecurrente: false,
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al actualizar ingreso: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    try {
      await _remoteDataSource.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al eliminar gasto: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteIncome(String id) async {
    try {
      await _remoteDataSource.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al eliminar ingreso: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'gasto', fechaDesde: start, fechaHasta: end);
      return Right(
        transactions
            .map((TransactionBackendModel tx) => _mapModelToExpense(tx))
            .toList(),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al obtener gastos por período: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<IncomeEntity>>> getIncomesByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'ingreso', fechaDesde: start, fechaHasta: end);
      return Right(
        transactions
            .map((TransactionBackendModel tx) => _mapModelToIncome(tx))
            .toList(),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al obtener ingresos por período: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesByCategory(
    String category,
  ) async {
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'gasto', categoriaId: category);
      return Right(
        transactions
            .map((TransactionBackendModel tx) => _mapModelToExpense(tx))
            .toList(),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al obtener gastos por categoría: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<IncomeEntity>>> getIncomesBySource(
    String source,
  ) async {
    try {
      final List<TransactionBackendModel> transactions = await _remoteDataSource
          .list(tipo: 'ingreso');
      return Right(
        transactions
            .where(
              (TransactionBackendModel tx) =>
                  tx.descripcion.toLowerCase().contains(source.toLowerCase()),
            )
            .map((TransactionBackendModel tx) => _mapModelToIncome(tx))
            .toList(),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al obtener ingresos por fuente: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, double>> getTotalExpenses(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final Either<Failure, List<ExpenseEntity>> result =
          await getExpensesByPeriod(start, end);

      return result.fold(
        (Failure l) => Left(l),
        (List<ExpenseEntity> expenses) => Right(
          expenses.fold<double>(
            0,
            (double sum, ExpenseEntity expense) => sum + expense.amount,
          ),
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al calcular total de gastos: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, double>> getTotalIncomes(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final Either<Failure, List<IncomeEntity>> result =
          await getIncomesByPeriod(start, end);

      return result.fold(
        (Failure l) => Left(l),
        (List<IncomeEntity> incomes) => Right(
          incomes.fold<double>(
            0,
            (double sum, IncomeEntity income) => sum + income.amount,
          ),
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al calcular total de ingresos: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, double>> getBalance(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final resultIncomes = await getTotalIncomes(start, end);
      final resultExpenses = await getTotalExpenses(start, end);

      return resultIncomes.fold(
        (Failure l) => Left(l),
        (double incomes) => resultExpenses.fold(
          (Failure l) => Left(l),
          (double expenses) => Right(incomes - expenses),
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Error al calcular balance: $e'));
    }
  }

  // Métodos de mapeo
  ExpenseEntity _mapModelToExpense(TransactionBackendModel model) =>
      ExpenseEntity(
        id: model.id,
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
        deletedAt: model.deletedAt,
        deviceId: model.deviceId,
        version: model.version,
        syncStatus: model.syncStatus,
        title: model.descripcion,
        amount: model.montoAsDouble,
        date: model.fecha,
        category: model.categoriaId,
      );

  IncomeEntity _mapModelToIncome(TransactionBackendModel model) => IncomeEntity(
    id: model.id,
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
    deletedAt: model.deletedAt,
    deviceId: model.deviceId,
    version: model.version,
    syncStatus: model.syncStatus,
    title: model.descripcion,
    amount: model.montoAsDouble,
    date: model.fecha,
    source: model.descripcion, // Using description as source
  );
}
