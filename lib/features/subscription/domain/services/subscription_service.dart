import 'package:personal_finance/features/subscription/domain/entities/subscription_entity.dart';
import 'package:personal_finance/features/subscription/domain/repositories/i_subscription_repository.dart';
import 'package:personal_finance/features/subscription/domain/subscription_constants.dart';

/// Servicio de dominio para consultar el plan del usuario y controlar acceso a features.
///
/// No tiene dependencias de infraestructura — delega la persistencia en
/// [ISubscriptionRepository]. Mantiene un caché en memoria del estado actual.
///
/// Uso:
/// ```dart
/// final service = sl<SubscriptionService>();
/// if (service.canUse(PlanFeature.aiChat)) { ... }
/// if (service.isAtBudgetLimit(currentCount)) { showPaywall(); }
/// ```
class SubscriptionService {
  SubscriptionService({required ISubscriptionRepository repository})
      : _repository = repository;

  final ISubscriptionRepository _repository;
  SubscriptionEntity _current = SubscriptionEntity.free;

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

  PlanLimits get limits => PlanLimits.forTier(_current.tier);

  // ---------------------------------------------------------------------------
  // Persistence (delegated to repository)
  // ---------------------------------------------------------------------------

  Future<void> load(String userId) async {
    _current = await _repository.load(userId);
  }

  Stream<SubscriptionEntity> watch(String userId) =>
      _repository.watch(userId);

  Future<void> save(String userId, SubscriptionEntity subscription) async {
    await _repository.save(userId, subscription);
    _current = subscription;
  }

  void updateLocal(SubscriptionEntity subscription) {
    _current = subscription;
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  bool _isAtLimit(int max, int current) {
    if (max == PlanLimits.unlimited) return false;
    return current >= max;
  }
}
