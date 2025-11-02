import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/accounts/data/datasources/account_remote_data_source.dart';
import 'package:personal_finance/features/accounts/data/models/account_model.dart';
import 'package:personal_finance/features/accounts/domain/entities/account.dart';
import 'package:personal_finance/features/accounts/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._remoteDataSource);

  final AccountRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<Account>>> getAccounts() async {
    try {
      final List<AccountModel> accounts = await _remoteDataSource.getAccounts();
      return Right(
        accounts.map((AccountModel model) => model.toEntity()).toList(),
      );
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account>> getAccount(String id) async {
    try {
      final AccountModel account = await _remoteDataSource.getAccount(id);
      return Right(account.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account>> createAccount(Account account) async {
    try {
      final AccountModel model = AccountModel.fromEntity(account);
      final AccountModel createdAccount = await _remoteDataSource.createAccount(
        model,
      );
      return Right(createdAccount.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account>> updateAccount(Account account) async {
    try {
      final AccountModel model = AccountModel.fromEntity(account);
      final AccountModel updatedAccount = await _remoteDataSource.updateAccount(
        model,
      );
      return Right(updatedAccount.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount(String id) async {
    try {
      await _remoteDataSource.deleteAccount(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
