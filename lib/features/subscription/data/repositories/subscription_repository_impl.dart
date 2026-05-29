import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_finance/features/subscription/domain/entities/subscription_entity.dart';
import 'package:personal_finance/features/subscription/domain/repositories/i_subscription_repository.dart';

class SubscriptionRepositoryImpl implements ISubscriptionRepository {
  const SubscriptionRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  // Path canónico — todos los nuevos documentos se escriben aquí.
  DocumentReference<Map<String, dynamic>> _currentDoc(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current');

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('subscription');

  @override
  Future<SubscriptionEntity> load(String userId) async {
    try {
      // 1. Intentar el path canónico primero (ruta rápida post-migración).
      final snap = await _currentDoc(userId).get();
      if (snap.exists && snap.data() != null) {
        return _resolveExpiration(SubscriptionEntity.fromMap(snap.data()!));
      }

      // 2. Fallback: buscar cualquier documento en la colección.
      //    Cubre datos legacy con IDs autogenerados o pruebas manuales.
      final query = await _collection(userId).limit(1).get();
      if (query.docs.isEmpty) return SubscriptionEntity.free;

      final entity = _resolveExpiration(
        SubscriptionEntity.fromMap(query.docs.first.data()),
      );

      // 3. Migrar al path canónico para que lecturas futuras (incluido watch)
      //    encuentren siempre 'current'.
      await save(userId, entity);

      return entity;
    } catch (_) {
      return SubscriptionEntity.free;
    }
  }

  @override
  Future<void> save(String userId, SubscriptionEntity subscription) =>
      _currentDoc(userId).set(subscription.toMap());

  @override
  Stream<SubscriptionEntity> watch(String userId) =>
      _currentDoc(userId).snapshots().map(
            (snap) =>
                (!snap.exists || snap.data() == null)
                    ? SubscriptionEntity.free
                    : _resolveExpiration(
                        SubscriptionEntity.fromMap(snap.data()!),
                      ),
          );

  SubscriptionEntity _resolveExpiration(SubscriptionEntity entity) {
    if (entity.expiresAt != null &&
        entity.expiresAt!.isBefore(DateTime.now())) {
      return entity.copyWith(status: SubscriptionStatus.expired);
    }
    return entity;
  }
}
