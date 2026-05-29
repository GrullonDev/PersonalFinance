import 'package:personal_finance/features/subscription/domain/entities/subscription_entity.dart';

/// Contrato de persistencia para el estado de suscripción del usuario.
///
/// El domain layer depende de esta abstracción; el data layer provee la
/// implementación concreta (Firestore).
abstract class ISubscriptionRepository {
  /// Carga la suscripción desde el backend y resuelve expiración.
  Future<SubscriptionEntity> load(String userId);

  /// Persiste [subscription] para [userId].
  Future<void> save(String userId, SubscriptionEntity subscription);

  /// Escucha cambios en tiempo real (útil tras completar un pago).
  Stream<SubscriptionEntity> watch(String userId);
}
