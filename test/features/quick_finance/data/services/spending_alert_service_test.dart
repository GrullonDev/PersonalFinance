import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/core/services/notifications/notification_service.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_preferences.dart';
import 'package:personal_finance/features/notifications/domain/repositories/notification_repository.dart';
import 'package:personal_finance/features/quick_finance/data/services/spending_alert_service.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

TransactionEntity _tx(
  double amount,
  DateTime date, {
  TransactionType type = TransactionType.expense,
  String? category,
}) => TransactionEntity(
  id: '${date.millisecondsSinceEpoch}$amount$category',
  userId: 'u1',
  type: type,
  amount: amount,
  note: '',
  categoryId: category,
  createdAt: date,
  updatedAt: date,
  syncStatus: SyncStatus.synced,
  version: 1,
  deviceId: 'd1',
);

void main() {
  late MockNotificationService notif;
  late MockNotificationRepository repo;
  late SharedPreferences prefs;
  final now = DateTime(2026, 9, 20);

  // Gastos > ingresos y "comida" disparada respecto al historial.
  final transactions = [
    for (var i = 1; i <= 3; i++)
      _tx(500, DateTime(2026, 9 - i, 10), category: 'comida'),
    _tx(300, DateTime(2026, 9), type: TransactionType.income),
    _tx(900, DateTime(2026, 9, 5), category: 'comida'),
  ];

  void stubPrefs({required bool enabled}) {
    when(() => repo.getPreferences()).thenAnswer(
      (_) async => Right(
        NotificationPreferences(
          emailEnabled: true,
          pushEnabled: true,
          marketingEnabled: false,
          budgetAlertsEnabled: enabled,
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    notif = MockNotificationService();
    repo = MockNotificationRepository();
    when(
      () => notif.notifySpendingDeviation(
        key: any(named: 'key'),
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {});
  });

  SpendingAlertService build() => SpendingAlertService(
    prefs: prefs,
    notificationService: notif,
    notificationRepository: repo,
  );

  test('notifica los desvíos detectados una sola vez por mes', () async {
    stubPrefs(enabled: true);
    final service = SpendingAlertService(
      prefs: prefs,
      notificationService: notif,
      notificationRepository: repo,
      maxAlertsPerRun: 5,
    );

    final first = await service.evaluate(transactions, now: now);
    expect(first, hasLength(3));
    verify(
      () => notif.notifySpendingDeviation(
        key: any(named: 'key'),
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).called(3);

    final second = await service.evaluate(transactions, now: now);
    expect(second, isEmpty);
    verifyNever(
      () => notif.notifySpendingDeviation(
        key: any(named: 'key'),
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    );
  });

  test('no notifica si el usuario desactivó las alertas', () async {
    stubPrefs(enabled: false);
    final sent = await build().evaluate(transactions, now: now);
    expect(sent, isEmpty);
    verifyNever(
      () => notif.notifySpendingDeviation(
        key: any(named: 'key'),
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    );
  });

  test('descarta las claves de meses anteriores', () async {
    stubPrefs(enabled: true);
    await prefs.setStringList(SpendingAlertService.notifiedKeysPref, [
      'spendingAboveIncome|2026-08',
    ]);
    await build().evaluate(transactions, now: now);
    final stored = prefs.getStringList(SpendingAlertService.notifiedKeysPref)!;
    expect(stored, isNot(contains('spendingAboveIncome|2026-08')));
    expect(stored, contains('spendingAboveIncome|2026-09'));
  });

  test('respeta el máximo de alertas por ejecución', () async {
    stubPrefs(enabled: true);
    final service = SpendingAlertService(
      prefs: prefs,
      notificationService: notif,
      notificationRepository: repo,
      maxAlertsPerRun: 1,
    );
    final sent = await service.evaluate(transactions, now: now);
    expect(sent, hasLength(1));
    expect(sent.first.key, 'spendingAboveIncome|2026-09');
  });
}
