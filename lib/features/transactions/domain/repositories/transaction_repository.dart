import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getTransactions();
  Future<Either<Failure, Transaction>> getTransaction(String id);
  Future<Either<Failure, Transaction>> createTransaction(
    Transaction transaction,
  );
  Future<Either<Failure, Transaction>> updateTransaction(
    Transaction transaction,
  );
  Future<Either<Failure, void>> deleteTransaction(String id);
}
