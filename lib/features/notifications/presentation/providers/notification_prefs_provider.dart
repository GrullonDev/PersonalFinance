import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_preferences.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_repository.dart';

class NotificationPrefsProvider extends ChangeNotifier {
  NotificationPrefsProvider(this._repo);

  final NotificationRepository _repo;

  bool _loading = false;
  String? _error;
  NotificationPreferences? _prefs;

  bool get loading => _loading;
  String? get error => _error;
  NotificationPreferences? get prefs => _prefs;

  Future<void> load() async {
    _setLoading(true);
    final Either<Failure, NotificationPreferences> r =
        await _repo.getPreferences();
    r.fold((Failure l) => _error = l.message, (NotificationPreferences p) {
      _error = null;
      _prefs = p;
    });
    _setLoading(false);
  }

  Future<bool> save({bool? email, bool? push, bool? marketing}) async {
    if (_prefs == null) return false;
    final NotificationPreferences original = _prefs!;
    _prefs = _prefs!.copyWith(
      emailEnabled: email,
      pushEnabled: push,
      marketingEnabled: marketing,
    );
    notifyListeners();
    final Either<Failure, NotificationPreferences> r = await _repo
        .updatePreferences(_prefs!);
    final bool ok = r.isRight();
    r.fold(
      (Failure l) {
        _error = l.message;
        _prefs = original; // rollback
        notifyListeners();
      },
      (NotificationPreferences p) {
        _error = null;
        _prefs = p;
        notifyListeners();
      },
    );
    return ok;
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
