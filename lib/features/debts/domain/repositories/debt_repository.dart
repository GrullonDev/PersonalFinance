import 'package:dartz/dartz.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';

abstract class DebtRepository {
  Future<Either<Failure, List<Debt>>> getDebts();
  Future<Either<Failure, Debt>> createDebt(Debt debt);
  Future<Either<Failure, Debt>> updateDebt(Debt debt);
  Future<Either<Failure, void>> deleteDebt(String id);
}
