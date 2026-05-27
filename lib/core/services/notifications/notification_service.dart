import 'package:personal_finance/core/services/notifications/local_notification_service.dart';
import 'package:personal_finance/core/services/notifications/push_notification_service.dart';

class NotificationService {
  final LocalNotificationService local;
  final PushNotificationService push;

  NotificationService({required this.local, required this.push});

  Future<void> init() async {
    await local.init();
    await push.init();
  }

  Future<void> requestAllPermissions() async {
    await local.requestPermissions();
    // Push permissions are requested during push.init() or can be explicit
  }

  // Convenience methods
  Future<void> schedulePaymentReminder(
    int id,
    String name,
    DateTime date,
  ) async {
    await local.scheduleNotification(
      id: id,
      title: 'Recordatorio de Pago',
      body: 'Tu pago de $name vence pronto.',
      scheduledDate: date,
    );
  }

  Future<void> notifyLowBudget(String category, double percentage) async {
    await local.showNotification(
      id: category.hashCode,
      title: 'Alerta de Presupuesto',
      body: 'Has consumido el $percentage% de tu presupuesto en $category.',
    );
  }

  /// Programa recordatorio para una deuda con pago en los próximos 7 días.
  /// Recibe datos primitivos para no crear dependencia core → features.
  Future<void> scheduleDebtPaymentReminder({
    required String debtId,
    required String debtName,
    required DateTime paymentDate,
    required double minimumPayment,
  }) async {
    final now = DateTime.now();
    final daysUntil = paymentDate.difference(now).inDays;
    if (daysUntil < 0 || daysUntil > 7) return;

    final String dayLabel = switch (daysUntil) {
      0 => 'HOY',
      1 => 'mañana',
      _ => 'en $daysUntil días',
    };

    // Notificar a las 9 AM del día del pago (o inmediatamente si es hoy)
    final scheduledDate = daysUntil == 0
        ? now.add(const Duration(minutes: 2))
        : DateTime(paymentDate.year, paymentDate.month, paymentDate.day, 9);

    await local.scheduleNotification(
      id: 'debt_pay_$debtId'.hashCode,
      title: '💳 Pago de deuda vence $dayLabel',
      body:
          '"$debtName": pago mínimo de Q${minimumPayment.toStringAsFixed(0)} vence $dayLabel. ¡No lo olvides!',
      scheduledDate: scheduledDate,
    );
  }
}
