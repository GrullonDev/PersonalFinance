import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/auto_capture/data/payment_capture_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(PaymentCaptureChannel.channelName);
  late List<Map<String, Object?>> nativeQueue;
  late SharedPreferences prefs;
  final postedAt = DateTime(2026, 9, 20, 13, 5);

  Map<String, Object?> notification(String title, String text) => {
    'source': 'notification',
    'packageName': 'com.google.android.apps.walletnfcrel',
    'title': title,
    'text': text,
    'postedAt': postedAt.millisecondsSinceEpoch,
  };

  setUp(() async {
    nativeQueue = [];
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'drainPending') {
            final items = List<Map<String, Object?>>.from(nativeQueue);
            nativeQueue.clear();
            return items;
          }
          if (call.method == 'isAccessGranted') return true;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  AutoCaptureService build({Future<String?> Function(String)? ai}) =>
      AutoCaptureService(
        channel: PaymentCaptureChannel(),
        prefs: prefs,
        aiCategorizer: ai,
      );

  test('convierte una notificación de Google Wallet en gasto', () async {
    final service = build();
    final received = <AutoCapturedTransaction>[];
    service.captured.listen(received.add);
    nativeQueue.add(notification('Starbucks', r'$4.75 con Visa ••1234'));

    await service.processPending();

    expect(received, hasLength(1));
    final tx = received.single;
    expect(tx.type, TransactionType.expense);
    expect(tx.amount, 4.75);
    expect(tx.note, 'Starbucks');
    expect(tx.category, 'comida');
    expect(tx.occurredAt, postedAt);
    expect(tx.sourceLabel, 'Google Wallet');
  });

  test('atajo de Apple Pay', () async {
    final service = build();
    final received = <AutoCapturedTransaction>[];
    service.captured.listen(received.add);
    nativeQueue.add({
      'source': 'shortcut',
      'packageName': 'apple_pay',
      'amount': r'$12.30',
      'merchant': 'Uber',
      'kind': 'gasto',
      'postedAt': postedAt.millisecondsSinceEpoch,
    });

    await service.processPending();

    expect(received.single.amount, 12.3);
    expect(received.single.category, 'transporte');
    expect(received.single.sourceLabel, 'Apple Pay');
  });

  test('usa la IA cuando el comercio no es conocido', () async {
    final service = build(ai: (_) async => 'Hogar');
    final received = <AutoCapturedTransaction>[];
    service.captured.listen(received.add);
    nativeQueue.add(notification('Casa Bonita XYZ', 'Q300.00'));

    await service.processPending();

    expect(received.single.category, 'hogar');
  });

  test('no registra dos veces la misma notificación', () async {
    final service = build();
    final received = <AutoCapturedTransaction>[];
    service.captured.listen(received.add);
    final n = notification('Starbucks', r'$4.75');

    nativeQueue.add(n);
    await service.processPending();
    nativeQueue.add(n);
    await service.processPending();

    expect(received, hasLength(1));
  });

  test('descarta notificaciones que no entiende', () async {
    final service = build();
    final received = <AutoCapturedTransaction>[];
    service.captured.listen(received.add);
    nativeQueue.add({
      ...notification('Banco', 'Tu estado de cuenta está listo'),
      'packageName': 'com.banco.app',
    });

    await service.processPending();

    expect(received, isEmpty);
  });

  test('sin oyentes o desactivado no vacía la cola nativa', () async {
    final service = build();
    nativeQueue.add(notification('Starbucks', r'$4.75'));

    await service.processPending();
    expect(nativeQueue, hasLength(1));

    await service.setEnabled(enabled: false);
    service.captured.listen((_) {});
    await service.processPending();
    expect(nativeQueue, hasLength(1));
  });
}
