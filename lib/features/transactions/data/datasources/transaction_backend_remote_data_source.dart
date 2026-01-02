import 'package:cloud_firestore/cloud_firestore.dart';
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

      if (fechaDesde != null) {
        query = query.where('fecha', isGreaterThanOrEqualTo: _fmt(fechaDesde));
      }
      if (fechaHasta != null) {
        query = query.where('fecha', isLessThanOrEqualTo: _fmt(fechaHasta));
      }
      if (categoriaId != null && categoriaId != '0' && categoriaId.isNotEmpty) {
        query = query.where('categoria_id', isEqualTo: categoriaId);
      }
      if (tipo != null && tipo.isNotEmpty) {
        query = query.where('tipo', isEqualTo: tipo);
      }

      // Order by date desc
      query = query.orderBy('fecha', descending: true);

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      return snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                TransactionBackendModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .toList();
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

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
