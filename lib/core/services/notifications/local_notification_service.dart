import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';

import 'package:personal_finance/core/services/navigation_service.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_inbox_repository.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_item.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final NavigationService _navigationService;
  final NotificationInboxRepository _inboxRepository;

  LocalNotificationService(this._navigationService, this._inboxRepository);

  Future<void> init() async {
    // 1. Initialize Timezone
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 5),
      );
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('Error or timeout initializing timezone: $e');
      // Fallback to UTC if timezone cannot be determined
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    // 4. Combine settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // 5. Initialize
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null && details.payload!.isNotEmpty) {
          _navigationService.navigateTo(details.payload!);
        } else {
          _navigationService.navigateTo(RoutePath.notificationsInbox);
        }
      },
    );
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? result =
          await androidImplementation?.requestNotificationsPermission();
      return result ?? false;
    }
    return false;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'personal_finance_channel',
          'Alertas de Finanzas',
          channelDescription:
              'Notificaciones sobre pagos, metas y presupuestos',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );

    // Save to inbox
    await _inboxRepository.saveNotification(
      NotificationItem(
        id: id.toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: 'local',
      ),
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'personal_finance_scheduled',
            'Recordatorios Programados',
            channelDescription: 'Recordatorios de pagos y vencimientos',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint('Exact alarms not permitted, scheduling inexactly instead: ${e.message}');
        try {
          await _notificationsPlugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'personal_finance_scheduled',
                'Recordatorios Programados',
                channelDescription: 'Recordatorios de pagos y vencimientos',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        } catch (e2) {
          debugPrint('Failed to schedule inexact notification: $e2');
        }
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('Unexpected error scheduling notification: $e');
    }

    // For scheduled notifications, we don't save to inbox yet
    // because it hasn't "happened" for the user.
    // In a real app, you might want a worker that saves it when it fires.
  }

  Future<void> scheduleStreakReminder(int streak) async {
    await cancelNotification(9999);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 20);

    final String body =
        streak > 0
            ? 'Llevas una racha de $streak días. ¡Añade una transacción hoy para mantenerla viva! 🔥'
            : '¡Empieza una racha de ahorro! Registra tus movimientos hoy para mantener el control. 💰';

    await scheduleNotification(
      id: 9999,
      title: '¡Mantén tu racha de ahorro! ⚡',
      body: body,
      scheduledDate: tomorrow,
    );
  }

  Future<void> scheduleWeeklySummary() async {
    await cancelNotification(9998);
    final now = DateTime.now();
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) {
      daysUntilSunday += 7;
    }
    final nextSunday = DateTime(
      now.year,
      now.month,
      now.day + daysUntilSunday,
      20,
    );

    await scheduleNotification(
      id: 9998,
      title: 'Resumen Semanal de Finanzas 📊',
      body:
          'Tu resumen semanal ya está listo. Abre la app para ver tus balances y consejos de ahorro personalizados.',
      scheduledDate: nextSunday,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}
