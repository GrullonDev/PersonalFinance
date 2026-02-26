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
}
