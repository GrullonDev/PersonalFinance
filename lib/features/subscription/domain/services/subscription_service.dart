import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_finance/features/subscription/domain/entities/subscription_entity.dart';
import 'package:personal_finance/features/subscription/domain/subscription_constants.dart';

/// Servicio central para consultar el plan del usuario y controlar acceso a features.
///
/// Uso:
/// ```dart
/// final service = sl<SubscriptionService>();
/// if (service.canUse(PlanFeature.aiChat)) { ... }
/// if (service.isAtBudgetLimit(currentCount)) { showPaywall(); }
/// ```
class SubscriptionService {
  final FirebaseFirestore _firestore;

  SubscriptionEntity _current = SubscriptionEntity.free;

  SubscriptionService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  SubscriptionEntity get current => _current;
  bool get isPremium => _current.isPremium;

  // ---------------------------------------------------------------------------
  // Feature gate
  // ---------------------------------------------------------------------------

  bool canUse(PlanFeature feature) {
    if (_current.isPremium) return true;
    return PlanFeatures.freeFeatures.contains(feature);
  }

  // ---------------------------------------------------------------------------
  // Limit checks
  // ---------------------------------------------------------------------------

  bool isAtBudgetLimit(int currentCount) =>
      _isAtLimit(PlanLimits.forTier(_current.tier).maxBudgets, currentCount);

  bool isAtGoalLimit(int currentCount) =>
      _isAtLimit(PlanLimits.forTier(_current.tier).maxGoals, currentCount);

  bool isAtAccountLimit(int currentCount) =>
      _isAtLimit(PlanLimits.forTier(_current.tier).maxAccounts, currentCount);

  bool _isAtLimit(int max, int current) {
    if (max == PlanLimits.unlimited) return false;
    return current >= max;
  }

  PlanLimits get limits => PlanLimits.forTier(_current.tier);

  // ---------------------------------------------------------------------------
  // Remote sync
  // ---------------------------------------------------------------------------

  /// Carga la suscripción desde Firestore y actualiza el estado local.
  Future<void> load(String userId) async {
    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('subscription')
              .doc('current')
              .get();

      if (!doc.exists || doc.data() == null) {
        _current = SubscriptionEntity.free;
        return;
      }

      final entity = SubscriptionEntity.fromMap(doc.data()!);

      // Verifica expiración de planes con fecha
      if (entity.tier != PlanTier.proLifetime &&
          entity.expiresAt != null &&
          entity.expiresAt!.isBefore(DateTime.now())) {
        _current = entity.copyWith(status: SubscriptionStatus.expired);
      } else {
        _current = entity;
      }
    } catch (_) {
      _current = SubscriptionEntity.free;
    }
  }

  /// Escucha cambios en tiempo real (útil tras completar un pago).
  Stream<SubscriptionEntity> watch(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .snapshots()
          .map(
            (snap) =>
                (!snap.exists || snap.data() == null)
                    ? SubscriptionEntity.free
                    : _resolveExpiration(
                        SubscriptionEntity.fromMap(snap.data()!),
                      ),
          );

  SubscriptionEntity _resolveExpiration(SubscriptionEntity entity) {
    if (entity.tier != PlanTier.proLifetime &&
        entity.expiresAt != null &&
        entity.expiresAt!.isBefore(DateTime.now())) {
      return entity.copyWith(status: SubscriptionStatus.expired);
    }
    return entity;
  }

  /// Actualiza la suscripción en Firestore (se llamará desde el flujo de pago).
  Future<void> save(String userId, SubscriptionEntity subscription) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .set(subscription.toMap());
    _current = subscription;
  }

  void updateLocal(SubscriptionEntity subscription) {
    _current = subscription;
  }
}
