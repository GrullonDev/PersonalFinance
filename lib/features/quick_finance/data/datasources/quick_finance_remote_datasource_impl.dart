import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_finance/core/constants/enums.dart';
import '../models/transaction_model.dart';
import '../models/sync_operation_model.dart';
import 'quick_finance_remote_datasource.dart';

/// Implementación Firestore del datasource remoto.
///
/// Estructura de colecciones:
///   `users/{userId}/transactions/{transactionId}`
///
/// Cada documento contiene todos los campos del [TransactionModel]
/// serializados con [toJson], más un `serverTimestamp` para ordenamiento.
class QuickFinanceRemoteDataSourceImpl implements QuickFinanceRemoteDataSource {
  final FirebaseFirestore firestore;

  QuickFinanceRemoteDataSourceImpl({required this.firestore});

  /// Referencia a la subcolección de transacciones de un usuario.
  CollectionReference<Map<String, dynamic>> _txCollection(String userId) =>
      firestore.collection('users').doc(userId).collection('transactions');

  // ---------------------------------------------------------------------------
  // Push — enviar operaciones pendientes
  // ---------------------------------------------------------------------------

  @override
  Future<void> pushPendingOperations({
    required String userId,
    required List<SyncOperationModel> operations,
    required List<TransactionModel> transactions,
  }) async {
    if (operations.isEmpty) return;

    // Construir un mapa transactionId → model para acceso O(1)
    final txMap = {for (final t in transactions) t.id: t};

    final batch = firestore.batch();

    for (final op in operations) {
      final model = txMap[op.transactionId];
      if (model == null) continue; // operación huérfana, skip

      final docRef = _txCollection(userId).doc(model.id);

      switch (op.action) {
        case SyncAction.create:
        case SyncAction.update:
          batch.set(docRef, {
            ...model.toJson(),
            'serverTimestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          break;

        case SyncAction.delete:
          // Soft-delete: escribimos el documento con deletedAt
          // (no borramos físicamente para mantener consistencia)
          batch.set(docRef, {
            ...model.toJson(),
            'serverTimestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          break;
      }
    }

    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Pull — descargar transacciones nuevas/modificadas
  // ---------------------------------------------------------------------------

  @override
  Future<List<TransactionModel>> pullLatestTransactions({
    required String userId,
    required DateTime lastSyncAt,
  }) async {
    final snapshot = await _txCollection(userId)
        .where('updatedAt', isGreaterThan: lastSyncAt.toIso8601String())
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      // Asegurar que el id del documento Firestore se use como id
      data['id'] = doc.id;
      return TransactionModel.fromJson(data);
    }).toList();
  }
}
