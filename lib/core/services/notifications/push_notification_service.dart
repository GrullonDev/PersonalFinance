import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_item.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_inbox_repository.dart';
import 'package:personal_finance/core/services/navigation_service.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'dart:developer' as developer;

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final NotificationInboxRepository _inboxRepository;
  final NavigationService _navigationService;

  PushNotificationService(this._inboxRepository, this._navigationService);

  Future<void> init() async {
    // Request permission (mostly for iOS)
    final NotificationSettings settings = await _fcm.requestPermission(
      
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      developer.log('User granted provisional permission');
    } else {
      developer.log('User declined or has not accepted permission');
    }

    // Get the token
    final String? token = await _fcm.getToken();
    developer.log('FCM Token: $token');

    // Any time the token refreshes, store it
    _fcm.onTokenRefresh.listen((String newToken) {
      developer.log('FCM Token Refreshed: $newToken');
      // TODO: Send token to your backend
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _saveToInbox(message);
      }
    });

    // Handle when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleDeepLinking(message);
    });
  }

  void _handleDeepLinking(RemoteMessage message) {
    developer.log('App opened via notification: ${message.data}');

    final type = message.data['type'];
    final screen = message.data['screen'];

    if (screen != null) {
      _navigationService.navigateTo(screen.toString());
    } else if (type == 'budget') {
      _navigationService.navigateTo(RoutePath.budgetsCrud);
    } else if (type == 'goal') {
      _navigationService.navigateTo(RoutePath.goalsCrud);
    } else {
      _navigationService.navigateTo(RoutePath.notificationsInbox);
    }
  }

  Future<void> _saveToInbox(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final item = NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification.title ?? 'Notificación',
      body: notification.body ?? '',
      timestamp: DateTime.now(),
      type: message.data['type']?.toString() ?? 'push',
    );

    await _inboxRepository.saveNotification(item);
  }

  Future<String?> getToken() async => await _fcm.getToken();
}

// Global function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // We need to initialize Hive here if we want to save to the inbox in background
  // However, usually we can just let the OS show the notification
  // and then when the user opens the app, we can fetch new notifications if we have an API
  // OR we can try to open the box here if Hive is not open.

  developer.log('Handling a background message: ${message.messageId}');
}
