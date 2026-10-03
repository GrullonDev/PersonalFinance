import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/core/services/notifications/notification_service.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_repository.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/services/spending_deviation_detector.dart';

/// Evalúa las transacciones y lanza una notificación local cuando detecta
/// que el dinero se está desviando (ver [SpendingDeviationDetector]).
///
/// Cada desvío se notifica como máximo una vez por mes y se respeta el
/// interruptor "Alertas de presupuesto" de las preferencias de notificación.
class SpendingAlertService {
  SpendingAlertService({
    required SharedPreferences prefs,
    required NotificationService notificationService,
    NotificationRepository? notificationRepository,
    SpendingDeviationDetector detector = const SpendingDeviationDetector(),
    this.maxAlertsPerRun = 2,
  }) : _prefs = prefs,
       _notificationService = notificationService,
       _notificationRepository = notificationRepository,
       _detector = detector;

  static const String notifiedKeysPref = 'spending_alerts_notified_keys';

  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  final NotificationRepository? _notificationRepository;
  final SpendingDeviationDetector _detector;

  /// Evita saturar al usuario si aparecen varios desvíos a la vez.
  final int maxAlertsPerRun;

  bool _running = false;

  /// Devuelve los desvíos que se notificaron en esta ejecución.
  Future<List<SpendingDeviation>> evaluate(
    List<TransactionEntity> transactions, {
    DateTime? now,
    String currencySymbol = '',
  }) async {
    if (_running) return const [];
    _running = true;
    try {
      if (!await _alertsEnabled()) return const [];

      final date = now ?? DateTime.now();
      final deviations = _detector.detect(
        transactions,
        now: date,
        currencySymbol: currencySymbol,
      );

      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      // Sólo se conservan las claves del mes en curso.
      final notified =
          (_prefs.getStringList(notifiedKeysPref) ?? const <String>[])
              .where((k) => k.contains('|$monthKey'))
              .toSet();

      final sent = <SpendingDeviation>[];
      for (final d in deviations) {
        if (sent.length >= maxAlertsPerRun) break;
        if (notified.contains(d.key)) continue;
        await _notificationService.notifySpendingDeviation(
          key: d.key,
          title: d.title,
          body: d.body,
        );
        notified.add(d.key);
        sent.add(d);
      }

      await _prefs.setStringList(notifiedKeysPref, notified.toList());
      return sent;
    } catch (e) {
      debugPrint('SpendingAlertService: error evaluando desvíos: $e');
      return const [];
    } finally {
      _running = false;
    }
  }

  Future<bool> _alertsEnabled() async {
    final repo = _notificationRepository;
    if (repo == null) return true;
    final result = await repo.getPreferences();
    return result.fold((_) => true, (p) => p.budgetAlertsEnabled);
  }
}
