import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_local_datasource_impl.dart';
import 'package:personal_finance/features/quick_finance/data/models/sync_operation_model.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';

// ---------------------------------------------------------------------------
// Mocks & Fakes
// ---------------------------------------------------------------------------

class MockTransactionBox extends Mock implements Box<TransactionModel> {}

class MockSyncOperationBox extends Mock implements Box<SyncOperationModel> {}

class FakeSyncOperationModel extends Fake implements SyncOperationModel {}

class FakeTransactionModel extends Fake implements TransactionModel {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TransactionModel _makeTransaction({
  String id = 'tx1',
  SyncStatus syncStatus = SyncStatus.pending,
  DateTime? deletedAt,
}) =>
    TransactionModel(
      id: id,
      userId: 'user1',
      type: TransactionType.expense,
      amount: 50.0,
      note: 'test',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      deletedAt: deletedAt,
      syncStatus: syncStatus,
      version: 1,
      deviceId: 'device1',
    );

SyncOperationModel _makeSyncOp({
  String id = 'op1',
  String transactionId = 'tx1',
  SyncAction action = SyncAction.create,
  bool processed = false,
}) =>
    SyncOperationModel(
      id: id,
      transactionId: transactionId,
      action: action,
      createdAt: DateTime(2026, 1, 1),
      processed: processed,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockTransactionBox transactionBox;
  late MockSyncOperationBox syncOperationBox;
  late QuickFinanceLocalDataSourceImpl datasource;

  setUpAll(() {
    registerFallbackValue(FakeSyncOperationModel());
    registerFallbackValue(FakeTransactionModel());
  });

  setUp(() {
    transactionBox = MockTransactionBox();
    syncOperationBox = MockSyncOperationBox();
    datasource = QuickFinanceLocalDataSourceImpl(
      transactionBox: transactionBox,
      syncOperationBox: syncOperationBox,
    );
  });

  // -------------------------------------------------------------------------
  group('saveTransaction', () {
    test('llama a box.put con la clave correcta', () async {
      final tx = _makeTransaction();
      when(() => transactionBox.put(tx.id, tx)).thenAnswer((_) async {});

      await datasource.saveTransaction(tx);

      verify(() => transactionBox.put('tx1', tx)).called(1);
    });
  });

  // -------------------------------------------------------------------------
  group('saveTransactions', () {
    test('llama a box.putAll con el mapa id→model', () async {
      final t1 = _makeTransaction(id: 'tx1');
      final t2 = _makeTransaction(id: 'tx2');
      when(() => transactionBox.putAll(any())).thenAnswer((_) async {});

      await datasource.saveTransactions([t1, t2]);

      verify(
        () => transactionBox.putAll({'tx1': t1, 'tx2': t2}),
      ).called(1);
    });

    test('no falla con lista vacía', () async {
      when(() => transactionBox.putAll(any())).thenAnswer((_) async {});
      await datasource.saveTransactions([]);
      verify(() => transactionBox.putAll({})).called(1);
    });
  });

  // -------------------------------------------------------------------------
  group('getTransactions', () {
    test('retorna todos los valores del box', () async {
      final tx = _makeTransaction();
      when(() => transactionBox.values).thenReturn([tx]);

      final result = await datasource.getTransactions();

      expect(result, [tx]);
    });

    test('retorna lista vacía cuando el box está vacío', () async {
      when(() => transactionBox.values).thenReturn([]);

      final result = await datasource.getTransactions();

      expect(result, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  group('deleteTransaction', () {
    test('llama a box.delete con el id correcto', () async {
      when(() => transactionBox.delete('tx1')).thenAnswer((_) async {});

      await datasource.deleteTransaction('tx1');

      verify(() => transactionBox.delete('tx1')).called(1);
    });
  });

  // -------------------------------------------------------------------------
  group('watchTransactions', () {
    test('emite el estado inicial del box antes de cualquier evento', () async {
      final tx = _makeTransaction();
      final controller = StreamController<BoxEvent>.broadcast();

      when(() => transactionBox.values).thenReturn([tx]);
      when(() => transactionBox.watch()).thenAnswer((_) => controller.stream);

      final stream = datasource.watchTransactions();
      final first = await stream.first;

      expect(first, [tx]);
      await controller.close();
    });

    test('emite nueva lista tras un evento del box', () async {
      final tx1 = _makeTransaction(id: 'tx1');
      final tx2 = _makeTransaction(id: 'tx2');
      final controller = StreamController<BoxEvent>();
      var callCount = 0;

      when(() => transactionBox.values).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? [tx1] : [tx1, tx2];
      });
      when(() => transactionBox.watch()).thenAnswer((_) => controller.stream);

      final future = expectLater(
        datasource.watchTransactions(),
        emitsInOrder([
          [tx1],
          [tx1, tx2],
        ]),
      );

      // Deja que el generador async* emita el valor inicial
      await Future.microtask(() {});

      // Dispara un cambio en el box
      controller.add(BoxEvent('tx2', tx2, false));

      await future;
      await controller.close();
    });
  });

  // -------------------------------------------------------------------------
  group('saveSyncOperation', () {
    test('llama a box.put con el id de la operación', () async {
      final op = _makeSyncOp();
      when(() => syncOperationBox.put(op.id, op)).thenAnswer((_) async {});

      await datasource.saveSyncOperation(op);

      verify(() => syncOperationBox.put('op1', op)).called(1);
    });
  });

  // -------------------------------------------------------------------------
  group('getPendingSyncOperations', () {
    test('retorna solo las operaciones con processed=false', () async {
      final pending = _makeSyncOp(id: 'op1', processed: false);
      final done = _makeSyncOp(id: 'op2', processed: true);
      when(() => syncOperationBox.values).thenReturn([pending, done]);

      final result = await datasource.getPendingSyncOperations();

      expect(result, [pending]);
    });

    test('retorna lista vacía si todas están procesadas', () async {
      final done = _makeSyncOp(processed: true);
      when(() => syncOperationBox.values).thenReturn([done]);

      final result = await datasource.getPendingSyncOperations();

      expect(result, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  group('markSyncOperationAsProcessed', () {
    test('guarda una copia con processed=true', () async {
      final op = _makeSyncOp(processed: false);
      when(() => syncOperationBox.get('op1')).thenReturn(op);
      when(
        () => syncOperationBox.put('op1', any()),
      ).thenAnswer((_) async {});

      await datasource.markSyncOperationAsProcessed('op1');

      final captured = verify(
        () => syncOperationBox.put('op1', captureAny()),
      ).captured.first as SyncOperationModel;

      expect(captured.processed, isTrue);
      expect(captured.id, 'op1');
      expect(captured.transactionId, op.transactionId);
      expect(captured.action, op.action);
    });

    test('no hace nada si la operación no existe', () async {
      when(() => syncOperationBox.get('missing')).thenReturn(null);

      await datasource.markSyncOperationAsProcessed('missing');

      verifyNever(() => syncOperationBox.put(any(), any()));
    });
  });
}
