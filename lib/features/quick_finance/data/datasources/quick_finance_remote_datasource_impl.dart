import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
  Future<Set<String>> pushPendingOperations({
    required String userId,
    required List<SyncOperationModel> operations,
    required List<TransactionModel> transactions,
  }) async {
    if (operations.isEmpty) return {};

    // Construir un mapa transactionId → model para acceso O(1)
    final txMap = {for (final t in transactions) t.id: t};

    final pushed = <String>{};

    for (final op in operations) {
      final model = txMap[op.transactionId];
      if (model == null) continue; // operación huérfana, skip

      // Omitir transacciones cuyo userId no coincida con el path — evita
      // permission-denied que bloquearía las operaciones restantes.
      if (model.userId != userId) {
        if (kDebugMode) {
          debugPrint(
            'SyncManager: skipping op ${op.id} — '
            'userId mismatch (${model.userId} != $userId)',
          );
        }
        continue;
      }

      final docRef = _txCollection(userId).doc(model.id);
      final payload = {
        ...TransactionFirestoreMapper.toFirestore(
          model,
          extras: TransactionFirestoreExtras(categoryId: model.categoryId),
        ),
        'serverTimestamp': FieldValue.serverTimestamp(),
      };

      try {
        // Escritura individual: un fallo no bloquea las demás operaciones.
        await docRef.set(payload, SetOptions(merge: true));
        pushed.add(op.id);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('SyncManager: push failed for op ${op.id}: $e');
          debugPrint('  userId (path): $userId');
          debugPrint('  transactionId: ${model.id}');
          debugPrint('  model.userId:  ${model.userId}');
          debugPrint('  amount:        ${model.amount} (${model.amount.runtimeType})');
          debugPrint('  type:          ${model.type}');
          debugPrint('  syncStatus:    ${model.syncStatus}');
          debugPrint('  version:       ${model.version} (${model.version.runtimeType})');
          debugPrint('  deviceId:      "${model.deviceId}" (len=${model.deviceId.length})');
          debugPrint('  note len:      ${model.note.length}');
          debugPrint('  deletedAt:     ${model.deletedAt}');
        }
        // No relanzar — continuar con la siguiente operación.
      }
    }

    return pushed;
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
