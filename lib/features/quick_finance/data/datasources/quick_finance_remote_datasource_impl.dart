import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';
import 'package:personal_finance/features/quick_finance/data/models/sync_operation_model.dart';
import 'package:personal_finance/features/quick_finance/data/mappers/legacy_transaction_mapper.dart';
import 'package:personal_finance/features/quick_finance/data/mappers/transaction_firestore_mapper.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_remote_datasource.dart';

/// Implementación Firestore del datasource remoto.
///
/// Estructura de colecciones:
///   `users/{userId}/transactions/{transactionId}`
///
/// Escritura: usa [TransactionFirestoreMapper.toFirestore] para el schema
/// canónico MVP. Lectura: usa [LegacyTransactionMapper] tolerante a ambos
/// schemas (MVP y legacy) y a todos los tipos de fecha.
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

      // Serializar con el schema canónico MVP (campos en camelCase, fechas en
      // ISO8601, syncStatus/type como strings).  Se usa en los tres casos
      // (create, update, delete) porque el soft-delete también escribe el
      // documento completo con deletedAt != null.
      final payload = {
        ...TransactionFirestoreMapper.toFirestore(
          model,
          extras: TransactionFirestoreExtras(categoryId: model.categoryId),
        ),
        'serverTimestamp': FieldValue.serverTimestamp(),
      };

      switch (op.action) {
        case SyncAction.create:
        case SyncAction.update:
        case SyncAction.delete:
          // merge: true preserva campos escritos por otros clientes/backend
          batch.set(docRef, payload, SetOptions(merge: true));
          break;
      }
    }

    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Fetch — descargar transacciones (completo o delta)
  // ---------------------------------------------------------------------------

  @override
  Future<List<TransactionModel>> fetchTransactions(
    String userId, {
    DateTime? updatedAfter,
  }) async {
    // Usar Timestamp nativo de Firestore para la comparación — evita fallos
    // cuando los documentos almacenan updatedAt como Timestamp en lugar de
    // ISO8601 string (tipos distintos no se comparan en Firestore).
    Query<Map<String, dynamic>> query = _txCollection(userId);

    if (updatedAfter != null) {
      query = query
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(updatedAfter))
          .orderBy('updatedAt', descending: true);
    }

    final snapshot = await query.get();

    // LegacyTransactionMapper es tolerante a ambos schemas (MVP y legacy) y
    // a todos los tipos de fecha. Pasamos userId explícitamente porque los
    // documentos legacy pueden no almacenarlo.
    return snapshot.docs
        .map(
          (doc) => LegacyTransactionMapper.fromMap(
            doc.data(),
            documentId: doc.id,
            userId: userId,
          ),
        )
        .toList();
  }
}
