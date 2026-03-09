import 'package:dartz/dartz.dart';
import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/debts/data/datasources/debt_remote_data_source.dart';
import 'package:personal_finance/features/debts/data/models/debt_model.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';
import 'package:personal_finance/utils/offline_sync_service.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtRemoteDataSource remoteDataSource;
  final OfflineSyncService offlineSyncService;

  DebtRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineSyncService,
  });

  @override
  Future<Either<Failure, List<Debt>>> getDebts() async {
    try {
      final List<DebtModel> remoteDebts = await remoteDataSource.getDebts();
      return Right(remoteDebts.map((m) => m.toEntity()).toList());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
        ServerFailure(message: 'Ocurrió un error inesperado: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Debt>> createDebt(Debt debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      final createdModel = await remoteDataSource.createDebt(model);
      return Right(createdModel.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure(message: 'Error al crear la deuda'));
    }
  }

  @override
  Future<Either<Failure, Debt>> updateDebt(Debt debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      final updatedModel = await remoteDataSource.updateDebt(debt.id, model);
      return Right(updatedModel.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure(message: 'Error al actualizar la deuda'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDebt(String id) async {
    try {
      await remoteDataSource.deleteDebt(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure(message: 'Error al eliminar la deuda'));
    }
  }
}
