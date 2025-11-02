import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:personal_finance/features/transactions/data/models/transaction_model.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._remoteDataSource);

  final TransactionRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions() async {
    try {
      final List<TransactionModel> transactions =
          await _remoteDataSource.getTransactions();
      return Right(
        transactions.map((TransactionModel model) => model.toEntity()).toList(),
      );
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> getTransaction(String id) async {
    try {
      final TransactionModel transaction = await _remoteDataSource
          .getTransaction(id);
      return Right(transaction.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> createTransaction(
    Transaction transaction,
  ) async {
    try {
      final TransactionModel model = TransactionModel.fromEntity(transaction);
      final TransactionModel createdTransaction = await _remoteDataSource
          .createTransaction(model);
      return Right(createdTransaction.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> updateTransaction(
    Transaction transaction,
  ) async {
    try {
      final TransactionModel model = TransactionModel.fromEntity(transaction);
      final TransactionModel updatedTransaction = await _remoteDataSource
          .updateTransaction(model);
      return Right(updatedTransaction.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await _remoteDataSource.deleteTransaction(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
