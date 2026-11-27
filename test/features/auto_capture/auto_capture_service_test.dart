import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
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
  late Directory dir;
  late Box<Map> inbox;
  bool failAck = false;
  int sequence = 0;
  String id() => 'native-${sequence++}';
  final postedAt = DateTime(2026, 9, 20, 13, 5);

  Map<String, Object?> notification(String title, String text) => {
    'id': id(),
    'owner': 'user-a',
    'source': 'notification',
    'packageName': 'com.google.android.apps.walletnfcrel',
    'title': title,
    'text': text,
    'postedAt': postedAt.millisecondsSinceEpoch,
  };

  setUp(() async {
    nativeQueue = [];
    dir = await Directory.systemTemp.createTemp('payment-inbox-');
    Hive.init(dir.path);
    inbox = await Hive.openBox<Map>('inbox');
    failAck = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'peekPending') return List.of(nativeQueue);
          if (call.method == 'acknowledge') {
            expect(
              inbox.isNotEmpty,
              isTrue,
              reason: 'durable write before ack',
            );
            if (failAck) throw PlatformException(code: 'disk');
            nativeQueue.removeWhere((r) => r['id'] == call.arguments['id']);
          }
          if (call.method == 'isAccessGranted') return true;
          return null;
        });
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  AutoCaptureService build({Future<String?> Function(String)? ai}) =>
      AutoCaptureService(
        channel: PaymentCaptureChannel(),
        prefs: prefs,
        inbox: inbox,
        aiCategorizer: ai,
      );

  test('convierte una notificación de Google Wallet en gasto', () async {
    final service = build();
    await service.setOwner('user-a');
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

  test('atajo de Wallet', () async {
    final service = build();
    await service.setOwner('user-a');
    final received = <AutoCapturedTransaction>[];
    service.captured.listen(received.add);
    nativeQueue.add({
      'id': id(),
      'owner': 'user-a',
      'source': 'shortcut',
      'packageName': 'wallet_shortcut',
      'amount': r'$12.30',
      'merchant': 'Uber',
      'kind': 'gasto',
      'postedAt': postedAt.millisecondsSinceEpoch,
    });

    await service.processPending();

    expect(received.single.amount, 12.3);
    expect(received.single.category, 'transporte');
    expect(received.single.sourceLabel, 'Wallet');
  });

  test('usa la IA cuando el comercio no es conocido', () async {
    final service = build(ai: (_) async => 'Hogar');
    await service.setOwner('user-a');
    final received = <AutoCapturedTransaction>[];
    service.captured.listen(received.add);
    nativeQueue.add(notification('Casa Bonita XYZ', 'Q300.00'));

    await service.processPending();

    expect(received.single.category, 'hogar');
  });

  test('no registra dos veces la misma notificación', () async {
    final service = build();
    await service.setOwner('user-a');
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
    await service.setOwner('user-a');
    final received = <AutoCapturedTransaction>[];
    service.captured.listen(received.add);
    nativeQueue.add({
      ...notification('Banco', 'Tu estado de cuenta está listo'),
      'packageName': 'com.banco.app',
    });

    await service.processPending();

    expect(received, isEmpty);
  });

  test('sin sesión o desactivado conserva la cola nativa', () async {
    final service = build();

    nativeQueue.add(notification('Starbucks', r'$4.75'));

    await service.processPending();
    expect(nativeQueue, hasLength(1));

    await prefs.setBool(AutoCaptureService.enabledPref, false);
    await service.setOwner('user-a');
    await service.setEnabled(enabled: false);
    service.captured.listen((_) {});
    await service.processPending();
    expect(nativeQueue, hasLength(1));
  });

  test(
    'el mismo pago avisado por Wallet y por el banco se registra una vez',
    () async {
      final service = build();
      await service.setOwner('user-a');
      final received = <AutoCapturedTransaction>[];
      service.captured.listen(received.add);
      nativeQueue.add(notification('Starbucks', 'Q45.00 con Visa ••1234'));
      await service.processPending();

      nativeQueue.add({
        'id': id(),
        'owner': 'user-a',
        'source': 'notification',
        'packageName': 'com.banco.app',
        'title': 'Banco',
        'text': 'Compra por Q45.00 en STARBUCKS con tarjeta ****1234',
        'postedAt':
            postedAt.add(const Duration(minutes: 2)).millisecondsSinceEpoch,
      });
      await service.processPending();

      expect(received, hasLength(1));
      expect(received.single.note, 'Starbucks');
    },
  );

  test('mensaje bancario de iOS se interpreta como notificación', () async {
    final service = build();
    await service.setOwner('user-a');
    final received = <AutoCapturedTransaction>[];
    service.captured.listen(received.add);
    nativeQueue.add({
      'id': id(),
      'owner': 'user-a',
      'source': 'notification',
      'packageName': 'ios.sms',
      'title': 'BI',
      'text': 'Se debitó Q.120.00 de su cuenta por compra en FARMACIA GALENO',
      'postedAt': postedAt.millisecondsSinceEpoch,
    });

    await service.processPending();

    final tx = received.single;
    expect(tx.type, TransactionType.expense);
    expect(tx.amount, 120);
    expect(tx.category, 'salud');
    expect(tx.sourceLabel, 'SMS del banco');
    expect(tx.rawText, contains('FARMACIA GALENO'));
  });

  test('reintento tras reinicio conserva revisión e identificador', () async {
    final service = build();
    await service.setOwner('user-a');
    nativeQueue.add(notification('Starbucks', 'Q45.00'));
    failAck = true;
    await expectLater(
      service.processPending(),
      throwsA(isA<PlatformException>()),
    );
    final original = service.suggestions.single;
    expect(nativeQueue, hasLength(1));
    await inbox.close();
    inbox = await Hive.openBox<Map>('inbox');
    failAck = false;
    final restarted = build();
    await restarted.setOwner('user-a');
    expect(nativeQueue, isEmpty);
    expect(restarted.suggestions.single.transactionId, original.transactionId);
    await restarted.dismiss(original.id);
    await restarted.processPending();
    expect(restarted.suggestions, isEmpty);
  });

  test(
    'una cuenta nueva no recibe capturas ambiguas ni de otra cuenta',
    () async {
      final service = build();
      nativeQueue.addAll([
        notification('A', 'Q45'),
        {...notification('Ambigua', 'Q45'), 'owner': null},
      ]);
      await service.setOwner('user-b');
      expect(service.suggestions, isEmpty);
      expect(nativeQueue, hasLength(2));
      await service.setOwner('user-a');
      expect(service.suggestions.single.note, 'A');
      final aid = service.suggestions.single.id;
      await service.setOwner('user-b');
      await service.dismiss(aid);
      await service.setOwner('user-a');
      expect(service.suggestions.single.id, aid);
      expect(nativeQueue.single['owner'], isNull);
    },
  );

  test(
    'compras legítimas del mismo importe conservan sus sugerencias',
    () async {
      final service = build();
      await service.setOwner('user-a');
      nativeQueue.addAll([
        notification('Starbucks', 'Q45.00'),
        notification('Starbucks', 'Q45.00'),
        {
          ...notification('Banco', 'Compra por Q45.00 en FARMACIA'),
          'packageName': 'banco',
        },
      ]);
      await service.processPending();
      expect(service.suggestions, hasLength(3));
    },
  );

  test(
    'ejemplo e importe ausente nunca se confunden con un pago completo',
    () async {
      final service = build();
      await service.setOwner('user-a');
      nativeQueue.add({
        'source': 'shortcut',
        'id': id(),
        'owner': 'user-a',
        'postedAt': 1,
      });
      await service.processPending();
      expect(service.suggestions.single.needsAmount, isTrue);
      await service.addSample();
      final sample = service.suggestions.singleWhere((r) => r.isSample);
      await service.markSaved(sample.id);
      expect(service.suggestions, hasLength(2));
      await service.dismiss(sample.id);
      expect(service.suggestions.single.isSample, isFalse);
    },
  );
}
