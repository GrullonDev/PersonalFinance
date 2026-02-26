import 'package:flutter/material.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_item.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_inbox_repository.dart';

class NotificationInboxProvider extends ChangeNotifier {
  final NotificationInboxRepository _repository;

  NotificationInboxProvider(this._repository);

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getNotifications();
    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (notifications) {
        _notifications = notifications;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String id) async {
    final result = await _repository.markAsRead(id);
    result.fold((failure) => _error = failure.message, (_) {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    });
  }

  Future<void> clearAll() async {
    final result = await _repository.clearAll();
    result.fold((failure) => _error = failure.message, (_) {
      _notifications = [];
      notifyListeners();
    });
  }

  Future<void> addNotification(NotificationItem notification) async {
    final result = await _repository.saveNotification(notification);
    result.fold((failure) => _error = failure.message, (_) {
      _notifications.insert(0, notification);
      notifyListeners();
    });
  }
}
