import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_local_datasource_impl.dart';
import 'package:personal_finance/features/quick_finance/data/models/sync_operation_model.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mocks & Fakes
// ─────────────────────────────────────────────────────────────────────────────

class MockTransactionBox extends Mock implements Box<TransactionModel> {}

class MockSyncOperationBox extends Mock implements Box<SyncOperationModel> {}

class FakeSyncOperationModel extends Fake implements SyncOperationModel {}

class FakeTransactionModel extends Fake implements TransactionModel {}

// ─────────────────────────────────────────────────────────────────────────────
// Builders
// ─────────────────────────────────────────────────────────────────────────────

TransactionModel _tx({
  String id = 'tx1',
  SyncStatus syncStatus = SyncStatus.pending,
  DateTime? deletedAt,
  DateTime? createdAt,
}) =>
    TransactionModel(
      id: id,
      userId: 'user1',
      type: TransactionType.expense,
      amount: 50.0,
      note: 'test',
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      deletedAt: deletedAt,
      syncStatus: syncStatus,
      version: 1,
      deviceId: 'device1',
    );

SyncOperationModel _op({
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

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockTransactionBox txBox;
  late MockSyncOperationBox opBox;
  late QuickFinanceLocalDataSourceImpl ds;

  setUpAll(() {
    registerFallbackValue(FakeSyncOperationModel());
    registerFallbackValue(FakeTransactionModel());
  });

  setUp(() {
    txBox = MockTransactionBox();
    opBox = MockSyncOperationBox();
    ds = QuickFinanceLocalDataSourceImpl(
      transactionBox: txBox,
      syncOperationBox: opBox,
    );
  });

  // ── saveTransaction ───────────────────────────────────────────────────────

  group('saveTransaction', () {
    test('llama box.put con id correcto', () async {
      final t = _tx();
      when(() => txBox.put(t.id, t)).thenAnswer((_) async {});

      await ds.saveTransaction(t);

      verify(() => txBox.put('tx1', t)).called(1);
    });
  });

  // ── saveTransactions ──────────────────────────────────────────────────────

  group('saveTransactions', () {
    test('llama box.putAll con mapa id→model', () async {
      final t1 = _tx(id: 'tx1');
      final t2 = _tx(id: 'tx2');
      when(() => txBox.putAll(any())).thenAnswer((_) async {});

      await ds.saveTransactions([t1, t2]);

      verify(() => txBox.putAll({'tx1': t1, 'tx2': t2})).called(1);
    });

    test('acepta lista vacía sin error', () async {
      when(() => txBox.putAll(any())).thenAnswer((_) async {});
      await ds.saveTransactions([]);
      verify(() => txBox.putAll({})).called(1);
    });
  });

  // ── getTransactions (activas, ordenadas) ──────────────────────────────────

  group('getTransactions', () {
    test('excluye soft-deleted (deletedAt != null)', () async {
      final active = _tx(id: 'tx1');
      final deleted = _tx(id: 'tx2', deletedAt: DateTime(2026, 1, 2));
      when(() => txBox.values).thenReturn([active, deleted]);

      final result = await ds.getTransactions();

      expect(result, [active]);
      expect(result.any((t) => t.deletedAt != null), isFalse);
    });

    test('ordena por createdAt descendente', () async {
      final older = _tx(id: 'tx_old', createdAt: DateTime(2026, 1, 1));
      final newer = _tx(id: 'tx_new', createdAt: DateTime(2026, 3, 1));
      when(() => txBox.values).thenReturn([older, newer]);

      final result = await ds.getTransactions();

      expect(result.first.id, 'tx_new');
      expect(result.last.id, 'tx_old');
    });

    test('retorna lista vacía cuando el box está vacío', () async {
      when(() => txBox.values).thenReturn([]);
      expect(await ds.getTransactions(), isEmpty);
    });
  });

  // ── getAllTransactions (incluye soft-deleted) ─────────────────────────────

  group('getAllTransactions', () {
    test('incluye transacciones con deletedAt', () async {
      final active = _tx(id: 'tx1');
      final deleted = _tx(id: 'tx2', deletedAt: DateTime(2026, 1, 2));
      when(() => txBox.values).thenReturn([active, deleted]);

      final result = await ds.getAllTransactions();

      expect(result.length, 2);
      expect(result.any((t) => t.deletedAt != null), isTrue);
    });

    test('ordena por createdAt descendente', () async {
      final older = _tx(id: 'a', createdAt: DateTime(2026, 1, 1));
      final newer = _tx(id: 'b', createdAt: DateTime(2026, 6, 1));
      when(() => txBox.values).thenReturn([older, newer]);

      final result = await ds.getAllTransactions();

      expect(result.first.id, 'b');
    });
  });

  // ── getTransaction ────────────────────────────────────────────────────────

  group('getTransaction', () {
    test('devuelve modelo cuando existe', () async {
      final t = _tx();
      when(() => txBox.get('tx1')).thenReturn(t);

      final result = await ds.getTransaction('tx1');

      expect(result, t);
    });

    test('devuelve null cuando no existe', () async {
      when(() => txBox.get('missing')).thenReturn(null);

      final result = await ds.getTransaction('missing');

      expect(result, isNull);
    });
  });

  // ── deleteTransaction ─────────────────────────────────────────────────────

  group('deleteTransaction', () {
    test('llama box.delete con el id correcto', () async {
      when(() => txBox.delete('tx1')).thenAnswer((_) async {});

      await ds.deleteTransaction('tx1');

      verify(() => txBox.delete('tx1')).called(1);
    });
  });

  // ── watchTransactions ─────────────────────────────────────────────────────

  group('watchTransactions', () {
    test('emite estado inicial al suscribirse', () async {
      final t = _tx();
      final ctrl = StreamController<BoxEvent>.broadcast();
      when(() => txBox.values).thenReturn([t]);
      when(() => txBox.watch()).thenAnswer((_) => ctrl.stream);

      final first = await ds.watchTransactions().first;

      expect(first, [t]);
      await ctrl.close();
    });

    test('excluye soft-deleted del estado inicial', () async {
      final active = _tx(id: 'tx1');
      final deleted = _tx(id: 'tx2', deletedAt: DateTime(2026, 1, 2));
      final ctrl = StreamController<BoxEvent>.broadcast();
      when(() => txBox.values).thenReturn([active, deleted]);
      when(() => txBox.watch()).thenAnswer((_) => ctrl.stream);

      final first = await ds.watchTransactions().first;

      expect(first.length, 1);
      expect(first.first.id, 'tx1');
      await ctrl.close();
    });

    test('emite lista actualizada tras evento del box', () async {
      final t1 = _tx(id: 'tx1', createdAt: DateTime(2026, 1, 1));
      final t2 = _tx(id: 'tx2', createdAt: DateTime(2026, 2, 1));
      final ctrl = StreamController<BoxEvent>();
      var callCount = 0;

      when(() => txBox.values).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? [t1] : [t1, t2];
      });
      when(() => txBox.watch()).thenAnswer((_) => ctrl.stream);

      final future = expectLater(
        ds.watchTransactions(),
        emitsInOrder([
          [t1],       // emisión inicial (t2 más reciente iría primero, pero aún no existe)
          [t2, t1],   // después del evento: ordenado por createdAt desc
        ]),
      );

      await Future.microtask(() {});
      ctrl.add(BoxEvent('tx2', t2, false));

      await future;
      await ctrl.close();
    });

    test('no emite transacciones soft-deleted tras evento del box', () async {
      final active = _tx(id: 'tx1');
      final deleted = _tx(id: 'tx2', deletedAt: DateTime(2026, 1, 2));
      final ctrl = StreamController<BoxEvent>();
      var callCount = 0;

      when(() => txBox.values).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? [active] : [active, deleted];
      });
      when(() => txBox.watch()).thenAnswer((_) => ctrl.stream);

      final future = expectLater(
        ds.watchTransactions(),
        emitsInOrder([
          [active],
          [active], // soft-deleted filtrado; solo activo permanece
        ]),
      );

      await Future.microtask(() {});
      ctrl.add(BoxEvent('tx2', deleted, false));

      await future;
      await ctrl.close();
    });
  });

  // ── saveSyncOperation ─────────────────────────────────────────────────────

  group('saveSyncOperation', () {
    test('llama box.put con el id de la operación', () async {
      final op = _op();
      when(() => opBox.put(op.id, op)).thenAnswer((_) async {});

      await ds.saveSyncOperation(op);

      verify(() => opBox.put('op1', op)).called(1);
    });
  });

  // ── getPendingSyncOperations ──────────────────────────────────────────────

  group('getPendingSyncOperations', () {
    test('retorna solo las operaciones con processed=false', () async {
      final pending = _op(id: 'op1', processed: false);
      final done = _op(id: 'op2', processed: true);
      when(() => opBox.values).thenReturn([pending, done]);

      final result = await ds.getPendingSyncOperations();

      expect(result, [pending]);
    });

    test('ordena por createdAt ascendente (FIFO)', () async {
      final first = SyncOperationModel(
        id: 'op1',
        transactionId: 'tx1',
        action: SyncAction.create,
        createdAt: DateTime(2026, 1, 1),
        processed: false,
      );
      final second = SyncOperationModel(
        id: 'op2',
        transactionId: 'tx2',
        action: SyncAction.create,
        createdAt: DateTime(2026, 1, 2),
        processed: false,
      );
      // Devolver en orden invertido para verificar el sort
      when(() => opBox.values).thenReturn([second, first]);

      final result = await ds.getPendingSyncOperations();

      expect(result.first.id, 'op1');
      expect(result.last.id, 'op2');
    });

    test('retorna vacío cuando todas están procesadas', () async {
      when(() => opBox.values).thenReturn([_op(processed: true)]);
      expect(await ds.getPendingSyncOperations(), isEmpty);
    });
  });

  // ── markSyncOperationAsProcessed ──────────────────────────────────────────

  group('markSyncOperationAsProcessed', () {
    test('guarda copia con processed=true usando copyWith', () async {
      final op = _op(processed: false);
      when(() => opBox.get('op1')).thenReturn(op);
      when(() => opBox.put('op1', any())).thenAnswer((_) async {});

      await ds.markSyncOperationAsProcessed('op1');

      final saved = verify(
        () => opBox.put('op1', captureAny()),
      ).captured.first as SyncOperationModel;

      expect(saved.processed, isTrue);
      expect(saved.id, op.id);
      expect(saved.transactionId, op.transactionId);
      expect(saved.action, op.action);
    });

    test('no hace nada si la operación no existe en el box', () async {
      when(() => opBox.get('missing')).thenReturn(null);

      await ds.markSyncOperationAsProcessed('missing');

      verifyNever(() => opBox.put(any(), any()));
    });
  });

  // ── deleteProcessedSyncOperations ─────────────────────────────────────────

  group('deleteProcessedSyncOperations', () {
    test('elimina solo operaciones con processed=true', () async {
      final pending = _op(id: 'op1', processed: false);
      final done1 = _op(id: 'op2', processed: true);
      final done2 = _op(id: 'op3', processed: true);
      when(() => opBox.values).thenReturn([pending, done1, done2]);
      when(() => opBox.deleteAll(any())).thenAnswer((_) async {});

      await ds.deleteProcessedSyncOperations();

      final deletedKeys = verify(
        () => opBox.deleteAll(captureAny()),
      ).captured.first as List;

      expect(deletedKeys, containsAll(['op2', 'op3']));
      expect(deletedKeys, isNot(contains('op1')));
    });

    test('no llama deleteAll si no hay operaciones procesadas', () async {
      when(() => opBox.values).thenReturn([_op(processed: false)]);
      when(() => opBox.deleteAll(any())).thenAnswer((_) async {});

      await ds.deleteProcessedSyncOperations();

      final captured = verify(
        () => opBox.deleteAll(captureAny()),
      ).captured.first as List;

      expect(captured, isEmpty);
    });

    test('no falla con box vacío', () async {
      when(() => opBox.values).thenReturn([]);
      when(() => opBox.deleteAll(any())).thenAnswer((_) async {});

      // Solo verifica que completa sin lanzar excepción
      await ds.deleteProcessedSyncOperations();
    });
  });

  // ── SyncOperationModel.copyWith ───────────────────────────────────────────

  group('SyncOperationModel.copyWith', () {
    test('copia con processed=true, mantiene resto', () {
      final original = _op(processed: false);
      final copy = original.copyWith(processed: true);

      expect(copy.processed, isTrue);
      expect(copy.id, original.id);
      expect(copy.transactionId, original.transactionId);
      expect(copy.action, original.action);
      expect(copy.createdAt, original.createdAt);
    });

    test('sin parámetros produce copia idéntica', () {
      final original = _op();
      final copy = original.copyWith();

      expect(copy, original); // Equatable compara por valor
    });

    test('puede cambiar múltiples campos a la vez', () {
      final original = _op(id: 'op1', processed: false);
      final copy = original.copyWith(
        id: 'op_new',
        action: SyncAction.delete,
        processed: true,
      );

      expect(copy.id, 'op_new');
      expect(copy.action, SyncAction.delete);
      expect(copy.processed, isTrue);
      expect(copy.transactionId, original.transactionId); // sin cambio
    });
  });
}
