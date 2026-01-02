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
      return Right(
        list
            .map(
              (TransactionBackendModel e) => TransactionBackend(
                id: e.id,
                tipo: e.tipo,
                monto: e.monto,
                descripcion: e.descripcion,
                fecha: e.fecha,
                categoriaId: e.categoriaId,
                esRecurrente: e.esRecurrente,
                profileId: e.profileId,
              ),
            )
            .toList(),
      );
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
      final TransactionBackendModel created = await _remote.create(
        TransactionBackendModel(
          tipo: tx.tipo,
          monto: tx.monto,
          descripcion: tx.descripcion,
          fecha: tx.fecha,
          categoriaId: tx.categoriaId,
          esRecurrente: tx.esRecurrente,
        ),
      );
      return Right(
        TransactionBackend(
          id: created.id,
          tipo: created.tipo,
          monto: created.monto,
          descripcion: created.descripcion,
          fecha: created.fecha,
          categoriaId: created.categoriaId,
          esRecurrente: created.esRecurrente,
          profileId: created.profileId,
        ),
      );
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
      final TransactionBackendModel updated = await _remote.update(
        tx.id!,
        TransactionBackendModel(
          id: tx.id,
          tipo: tx.tipo,
          monto: tx.monto,
          descripcion: tx.descripcion,
          fecha: tx.fecha,
          categoriaId: tx.categoriaId,
          esRecurrente: tx.esRecurrente,
        ),
      );
      return Right(
        TransactionBackend(
          id: updated.id,
          tipo: updated.tipo,
          monto: updated.monto,
          descripcion: updated.descripcion,
          fecha: updated.fecha,
          categoriaId: updated.categoriaId,
          esRecurrente: updated.esRecurrente,
          profileId: updated.profileId,
        ),
      );
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
