import 'package:permission_handler/permission_handler.dart';
import 'package:personal_finance/core/services/notifications/local_notification_service.dart';

class NotificationPermissionService {
  final LocalNotificationService _local;

  NotificationPermissionService(this._local);

  Future<bool> requestAll() async {
    // Request system permission via permission_handler as well for Android 13+
    final status = await Permission.notification.request();

    // Also trigger platform specific requests in services
    final localResult = await _local.requestPermissions();

    return status.isGranted || localResult;
  }

  Future<PermissionStatus> getStatus() async => await Permission.notification.status;
}
