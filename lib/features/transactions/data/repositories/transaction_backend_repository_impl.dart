import 'package:dartz/dartz.dart';
import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/transactions/data/datasources/transaction_backend_remote_data_source.dart';
import 'package:personal_finance/features/transactions/data/models/transaction_backend_model.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart';

class TransactionBackendRepositoryImpl implements TransactionBackendRepository {
  TransactionBackendRepositoryImpl(this._remote);

  final TransactionBackendRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<TransactionBackend>>> list({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? categoriaId,
    String? tipo,
  }) async {
    try {
      final List<TransactionBackendModel> list = await _remote.list(
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        categoriaId: categoriaId,
        tipo: tipo,
      );
      return Right(list.map((e) => e.toEntity()).toList());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionBackend>> create(
    TransactionBackend tx,
  ) async {
    try {
      final TransactionBackendModel model = TransactionBackendModel.fromEntity(
        tx,
      );
      final TransactionBackendModel created = await _remote.create(model);
      return Right(created.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionBackend>> update(
    TransactionBackend tx,
  ) async {
    try {
      final TransactionBackendModel model = TransactionBackendModel.fromEntity(
        tx,
      );
      final TransactionBackendModel updated = await _remote.update(
        tx.id,
        model,
      );
      return Right(updated.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _remote.delete(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
