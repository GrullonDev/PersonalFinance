import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/features/transactions/data/models/transaction_backend_model.dart';

abstract class TransactionBackendRemoteDataSource {
  Future<List<TransactionBackendModel>> list({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? categoriaId,
    String? tipo,
  });
  Future<TransactionBackendModel> getById(String id);
  Future<TransactionBackendModel> create(TransactionBackendModel tx);
  Future<TransactionBackendModel> update(String id, TransactionBackendModel tx);
  Future<void> delete(String id);
}

class TransactionBackendRemoteDataSourceImpl
    implements TransactionBackendRemoteDataSource {
  TransactionBackendRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw ApiException(message: 'User not authenticated', statusCode: 401);
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('users').doc(_uid).collection('transactions');

  @override
  Future<List<TransactionBackendModel>> list({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? categoriaId,
    String? tipo,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _transactionsCollection;

      // Filter by type only in Firestore to avoid composite index issues
      if (tipo != null && tipo.isNotEmpty) {
        query = query.where('tipo', isEqualTo: tipo);
      }

      // Removed server-side date filtering and sorting to prevent FAILED_PRECONDITION
      // until composite indexes are fully deployed.

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();

      List<TransactionBackendModel> results =
          snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    TransactionBackendModel.fromJson({
                      ...doc.data(),
                      'id': doc.id,
                    }),
              )
              .toList();

      // Client-side filtering
      if (fechaDesde != null) {
        final DateTime start = DateUtils.dateOnly(fechaDesde);
        results = results.where((tx) => !tx.fecha.isBefore(start)).toList();
      }

      if (fechaHasta != null) {
        final DateTime end = DateUtils.dateOnly(fechaHasta)
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
        results = results.where((tx) => !tx.fecha.isAfter(end)).toList();
      }

      if (categoriaId != null && categoriaId != '0' && categoriaId.isNotEmpty) {
        results = results.where((tx) => tx.categoriaId == categoriaId).toList();
      }

      // Client-side sorting
      results.sort((a, b) => b.fecha.compareTo(a.fecha));

      return results;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<TransactionBackendModel> getById(String id) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _transactionsCollection.doc(id).get();
      if (!doc.exists) {
        throw ApiException(message: 'Transaction not found', statusCode: 404);
      }
      return TransactionBackendModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<TransactionBackendModel> create(TransactionBackendModel tx) async {
    try {
      final DocumentReference<Map<String, dynamic>> docRef =
          _transactionsCollection.doc();
      final Map<String, dynamic> data = tx.toJson()..remove('id');
      await docRef.set(data);
      return TransactionBackendModel.fromJson({...data, 'id': docRef.id});
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
      final Map<String, dynamic> data = tx.toJson()..remove('id');
      await _transactionsCollection.doc(id).update(data);
      return TransactionBackendModel.fromJson({...data, 'id': id});
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _transactionsCollection.doc(id).delete();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }
}
