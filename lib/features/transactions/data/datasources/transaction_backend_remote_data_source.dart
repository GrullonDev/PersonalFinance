import 'package:flutter/material.dart';
import 'package:personal_finance/core/data/datasources/base_firestore_service.dart';
import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/features/transactions/data/models/transaction_backend_model.dart';

abstract class TransactionBackendRemoteDataSource {
  Future<List<TransactionBackendModel>> list({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? categoriaId,
    String? tipo,
    String? profileType,
  });
  Future<TransactionBackendModel> getById(String id);
  Future<TransactionBackendModel> create(TransactionBackendModel tx);
  Future<TransactionBackendModel> update(String id, TransactionBackendModel tx);
  Future<void> delete(String id);
}

class TransactionBackendRemoteDataSourceImpl
    extends BaseFirestoreService<TransactionBackendModel>
    implements TransactionBackendRemoteDataSource {
  @override
  String get collectionName => 'transactions';

  @override
  TransactionBackendModel fromFirestore(Map<String, dynamic> json) =>
      TransactionBackendModel.fromFirestore(json);

  @override
  Future<List<TransactionBackendModel>> list({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? categoriaId,
    String? tipo,
    String? profileType,
  }) async {
    try {
      List<TransactionBackendModel> results = await getAll();

      if (tipo != null && tipo.isNotEmpty) {
        results = results.where((tx) => tx.tipo == tipo).toList();
      }

      if (profileType != null && profileType.isNotEmpty) {
        results = results.where((tx) => tx.profileType == profileType).toList();
      }

      if (fechaDesde != null || fechaHasta != null) {
        final DateTime? start =
            fechaDesde != null ? DateUtils.dateOnly(fechaDesde) : null;
        final DateTime? end =
            fechaHasta != null
                ? DateUtils.dateOnly(fechaHasta)
                    .add(const Duration(days: 1))
                    .subtract(const Duration(milliseconds: 1))
                : null;

        results = results.where((tx) {
          // A transaction belongs to the period if either its user-entered
          // date (fecha) or its Firestore recording timestamp (createdAt)
          // falls within the range — covers backdated and forward-dated entries.
          final bool fechaInRange =
              (start == null ||
                  !DateUtils.dateOnly(tx.fecha).isBefore(start)) &&
              (end == null || !tx.fecha.isAfter(end));
          final bool createdAtInRange =
              (start == null ||
                  !DateUtils.dateOnly(tx.createdAt).isBefore(start)) &&
              (end == null || !tx.createdAt.isAfter(end));
          return fechaInRange || createdAtInRange;
        }).toList();
      }

      if (categoriaId != null && categoriaId != '0' && categoriaId.isNotEmpty) {
        results = results.where((tx) => tx.categoriaId == categoriaId).toList();
      }

      results.sort((a, b) => b.fecha.compareTo(a.fecha));

      return results;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<TransactionBackendModel> getById(String id) async {
    try {
      final model = await get(id);
      if (model == null) {
        throw ApiException(message: 'Transaction not found', statusCode: 404);
      }
      return model;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<TransactionBackendModel> create(TransactionBackendModel tx) async {
    try {
      await upsert(tx);
      return tx;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<TransactionBackendModel> update(
    String id,
    TransactionBackendModel tx,
  ) async {
    try {
      await upsert(tx);
      return tx;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await softDelete(id);
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }
}
