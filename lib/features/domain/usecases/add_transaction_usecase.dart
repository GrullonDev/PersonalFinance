import 'package:dartz/dartz.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/core/services/device_service.dart';
import 'package:personal_finance/utils/injection_container.dart';
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
  final String? profileType;

  const AddExpenseParams({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.description,
    this.notes,
    this.profileType,
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
  final String? profileType;

  const AddIncomeParams({
    required this.title,
    required this.amount,
    required this.date,
    required this.source,
    this.description,
    this.notes,
    this.profileType,
  });
}

/// Caso de uso para agregar transacciones
class AddTransactionUseCase {
  final TransactionRepository repository;

  const AddTransactionUseCase(this.repository);

  /// Agrega un nuevo gasto
  Future<Either<Failure, void>> addExpense(AddExpenseParams params) async {
    try {
      // Validaciones
      if (params.title.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'El título del gasto no puede estar vacío',
          ),
        );
      }
      if (params.amount <= 0) {
        return const Left(
          ValidationFailure(message: 'El monto del gasto debe ser mayor a 0'),
        );
      }
      if (params.category.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'La categoría del gasto no puede estar vacía',
          ),
        );
      }

      final now = DateTime.now();
      final deviceId = getIt<DeviceService>().deviceId;

      final ExpenseEntity expense = ExpenseEntity(
        id: 'exp_${now.microsecondsSinceEpoch}',
        createdAt: now,
        updatedAt: now,
        deviceId: deviceId,
        version: 1,
        title: params.title,
        amount: params.amount,
        date: params.date,
        category: params.category,
        description: params.description,
        notes: params.notes,
        profileType: params.profileType,
      );

      return await repository.addExpense(expense);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al agregar gasto: $e'));
    }
  }

  /// Agrega un nuevo ingreso
  Future<Either<Failure, void>> addIncome(AddIncomeParams params) async {
    try {
      // Validaciones
      if (params.title.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'El título del ingreso no puede estar vacío',
          ),
        );
      }
      if (params.amount <= 0) {
        return const Left(
          ValidationFailure(message: 'El monto del ingreso debe ser mayor a 0'),
        );
      }
      if (params.source.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'La fuente del ingreso no puede estar vacía',
          ),
        );
      }

      final now = DateTime.now();
      final deviceId = getIt<DeviceService>().deviceId;

      final IncomeEntity income = IncomeEntity(
        id: 'inc_${now.microsecondsSinceEpoch}',
        createdAt: now,
        updatedAt: now,
        deviceId: deviceId,
        version: 1,
        title: params.title,
        amount: params.amount,
        date: params.date,
        source: params.source,
        description: params.description,
        notes: params.notes,
        profileType: params.profileType,
      );

      return await repository.addIncome(income);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al agregar ingreso: $e'));
    }
  }
}
