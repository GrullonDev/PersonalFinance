import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';

abstract class TransactionBackendRepository {
  Future<Either<Failure, List<TransactionBackend>>> list({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? categoriaId,
    String? tipo,
  });
  Future<Either<Failure, TransactionBackend>> create(TransactionBackend tx);
  Future<Either<Failure, TransactionBackend>> update(TransactionBackend tx);
  Future<Either<Failure, void>> delete(int id);
}
