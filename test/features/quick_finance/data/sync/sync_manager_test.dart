import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_local_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_remote_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/models/sync_operation_model.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';
import 'package:personal_finance/features/quick_finance/data/sync/sync_manager.dart';

class _Local extends Mock implements QuickFinanceLocalDataSource {}

class _Remote extends Mock implements QuickFinanceRemoteDataSource {}

TransactionModel _tx(String id, SyncStatus status, {int version = 1}) =>
    TransactionModel(
      id: id,
      userId: 'u',
      type: TransactionType.expense,
      amount: 10,
      note: 'Uber',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
      syncStatus: status,
      version: version,
      deviceId: 'd',
    );

void main() {
  late _Local local;
  late _Remote remote;
  late SyncManager manager;
  late Map<String, TransactionModel> box;

  setUpAll(() {
    registerFallbackValue(_tx('x', SyncStatus.pending));
    registerFallbackValue(<SyncOperationModel>[]);
    registerFallbackValue(<TransactionModel>[]);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'quick_finance_hydrated_u': true});
    local = _Local();
    remote = _Remote();
    box = {};
    when(() => local.setUserId(any())).thenReturn(null);
    when(
      () => local.getAllTransactions(),
    ).thenAnswer((_) async => box.values.toList());
    when(
      () => local.getTransaction(any()),
    ).thenAnswer((inv) async => box[inv.positionalArguments.first as String]);
    when(() => local.saveTransaction(any())).thenAnswer((inv) async {
      final t = inv.positionalArguments.first as TransactionModel;
      box[t.id] = t;
    });
    when(() => local.saveTransactions(any())).thenAnswer((_) async {});
    when(
      () => local.markSyncOperationAsProcessed(any()),
    ).thenAnswer((_) async {});
    when(() => local.deleteProcessedSyncOperations()).thenAnswer((_) async {});
    when(
      () => remote.fetchTransactions(
        any(),
        updatedAfter: any(named: 'updatedAfter'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => remote.pushPendingOperations(
        userId: any(named: 'userId'),
        operations: any(named: 'operations'),
        transactions: any(named: 'transactions'),
      ),
    ).thenAnswer((inv) async {
      final ops = inv.namedArguments[#operations] as List<SyncOperationModel>;
      return {for (final o in ops) o.id};
    });
    manager = SyncManager(localDataSource: local, remoteDataSource: remote)
      ..setUserId('u');
  });

  test(
    'sube y marca sincronizado un movimiento pendiente sin operación',
    () async {
      box['1'] = _tx('1', SyncStatus.pending);
      when(() => local.getPendingSyncOperations()).thenAnswer((_) async => []);

      final result = await manager.syncNow();

      expect(result.pushedCount, 1);
      expect(box['1']!.syncStatus, SyncStatus.synced);
      // Las operaciones de autocorrección no existen en Hive.
      verifyNever(() => local.markSyncOperationAsProcessed(any()));
    },
  );

  test(
    'no marca sincronizado si el movimiento cambió mientras se subía',
    () async {
      box['1'] = _tx('1', SyncStatus.pending);
      when(() => local.getPendingSyncOperations()).thenAnswer(
        (_) async => [
          SyncOperationModel(
            id: 'op_1',
            transactionId: '1',
            action: SyncAction.create,
            createdAt: DateTime(2026),
            processed: false,
          ),
        ],
      );
      when(
        () => remote.pushPendingOperations(
          userId: any(named: 'userId'),
          operations: any(named: 'operations'),
          transactions: any(named: 'transactions'),
        ),
      ).thenAnswer((inv) async {
        // Llega una edición (versión 2) durante la subida.
        box['1'] = _tx('1', SyncStatus.pending, version: 2);
        final ops = inv.namedArguments[#operations] as List<SyncOperationModel>;
        return {for (final o in ops) o.id};
      });

      await manager.syncNow();

      expect(box['1']!.version, 2);
      expect(box['1']!.syncStatus, SyncStatus.pending);
      verify(() => local.markSyncOperationAsProcessed('op_1')).called(1);
    },
  );
}
