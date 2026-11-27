import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_event.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_state.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/add_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/delete_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/hydrate_current_user_transactions.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/watch_balance.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/watch_transactions.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/update_transaction.dart';
import 'package:personal_finance/features/quick_finance/data/sync/sync_manager.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';
import 'package:personal_finance/core/services/device_service.dart';
import 'package:personal_finance/core/services/notifications/notification_service.dart';
import 'package:personal_finance/core/services/notifications/local_notification_service.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';

class MockInbox extends Mock implements AutoCaptureService {}

// Mocks
class MockAddTransaction extends Mock implements AddTransaction {}

class MockDeleteTransaction extends Mock implements DeleteTransaction {}

class MockHydrateCurrentUserTransactions extends Mock
    implements HydrateCurrentUserTransactions {}

class MockWatchBalance extends Mock implements WatchBalance {}

class MockWatchTransactions extends Mock implements WatchTransactions {}

class MockUpdateTransaction extends Mock implements UpdateTransaction {}

class MockSyncManager extends Mock implements SyncManager {}

class MockAuthDataSource extends Mock implements AuthDataSource {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockDebtRepository extends Mock implements DebtRepository {}

class MockDeviceService extends Mock implements DeviceService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockLocalNotificationService extends Mock
    implements LocalNotificationService {}

QuickFinanceBloc _buildBloc({required MockAddTransaction mockAdd}) {
  final mockAuth = MockAuthDataSource();
  when(() => mockAuth.currentUserId).thenReturn('test-user');
  when(() => mockAuth.authStateChanges).thenAnswer((_) => Stream.empty());

  final mockSync = MockSyncManager();
  when(() => mockSync.syncStream).thenAnswer((_) => Stream.empty());

  final mockWatchTx = MockWatchTransactions();
  when(
    () => mockWatchTx(userId: any(named: 'userId')),
  ).thenAnswer((_) => Stream.empty());

  final mockWatchBal = MockWatchBalance();
  when(
    () => mockWatchBal(userId: any(named: 'userId')),
  ).thenAnswer((_) => Stream.empty());

  final mockDevice = MockDeviceService();
  when(() => mockDevice.deviceId).thenReturn('test-device');

  return QuickFinanceBloc(
    addTransaction: mockAdd,
    deleteTransaction: MockDeleteTransaction(),
    hydrateCurrentUserTransactions: MockHydrateCurrentUserTransactions(),
    watchBalance: mockWatchBal,
    watchTransactions: mockWatchTx,
    updateTransaction: MockUpdateTransaction(),
    syncManager: mockSync,
    authDataSource: mockAuth,
    goalRepository: MockGoalRepository(),
    debtRepository: MockDebtRepository(),
    deviceService: mockDevice,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      TransactionEntity(
        id: '',
        userId: '',
        type: TransactionType.expense,
        amount: 0,
        note: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        version: 1,
        deviceId: '',
      ),
    );
    registerFallbackValue(
      Goal(
        id: '',
        nombre: '',
        montoObjetivo: '',
        montoActual: '',
        fechaLimite: DateTime.now(),
      ),
    );
    registerFallbackValue(
      Debt(
        id: '',
        name: '',
        currentBalance: 0,
        originalAmount: 0,
        interestRate: 0,
        nextPaymentDate: DateTime.now(),
        minimumPayment: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deviceId: '',
        version: 1,
      ),
    );
  });

  final capture = AutoCapturedTransaction(
    id: "stable-1",
    owner: "test-user",
    type: TransactionType.expense,
    amount: 50.0,
    note: "McDonald's",
    occurredAt: DateTime(2026, 9, 25),
    sourceLabel: 'Google Wallet',
    category: 'comida',
  );

  group('QuickFinanceState pendingCaptures', () {
    test('initial state has empty pendingCaptures', () {
      const state = QuickFinanceState();
      expect(state.pendingCaptures, isEmpty);
    });

    test('initial state has needsNotificationAccess false', () {
      const state = QuickFinanceState();
      expect(state.needsNotificationAccess, isFalse);
    });

    test('initial state has needsShortcutsSetup false', () {
      const state = QuickFinanceState();
      expect(state.needsShortcutsSetup, isFalse);
    });

    test('copyWith adds pending capture', () {
      const state = QuickFinanceState();
      final updated = state.copyWith(pendingCaptures: [capture]);
      expect(updated.pendingCaptures, [capture]);
    });

    test('copyWith sets needsNotificationAccess', () {
      const state = QuickFinanceState();
      final updated = state.copyWith(needsNotificationAccess: true);
      expect(updated.needsNotificationAccess, isTrue);
    });

    test('copyWith sets needsShortcutsSetup', () {
      const state = QuickFinanceState();
      final updated = state.copyWith(needsShortcutsSetup: true);
      expect(updated.needsShortcutsSetup, isTrue);
    });

    test('AutoCaptureConfirmed carries edits', () {
      final e = AutoCaptureConfirmed(
        capture,
        editedNote: 'Edited',
        editedCategoryId: 'transporte',
      );
      expect(e.editedNote, 'Edited');
      expect(e.editedCategoryId, 'transporte');
    });

    test('AutoCaptureDismissed is equatable', () {
      final e1 = AutoCaptureDismissed(capture);
      final e2 = AutoCaptureDismissed(capture);
      expect(e1, equals(e2));
    });
  });

  group('QuickFinanceBloc auto-capture handlers', () {
    late QuickFinanceBloc bloc;
    late MockAddTransaction mockAdd;
    late MockInbox inbox;
    late List<AutoCapturedTransaction> pending;
    setUp(() {
      mockAdd = MockAddTransaction();
      inbox = MockInbox();
      pending = [capture];
      when(() => inbox.owner).thenReturn('test-user');
      when(() => inbox.suggestions).thenAnswer((_) => pending);
      when(() => inbox.markSaved(any())).thenAnswer((call) async {
        pending.removeWhere((c) => c.id == call.positionalArguments.first);
      });
      when(() => inbox.dismiss(any())).thenAnswer((_) async => pending.clear());
      GetIt.instance.registerSingleton<AutoCaptureService>(inbox);
      bloc = _buildBloc(mockAdd: mockAdd);
    });
    tearDown(() async {
      await bloc.close();
      await GetIt.instance.unregister<AutoCaptureService>();
    });
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('restores inbox without posting and dismisses durably', () async {
      bloc.add(const CaptureInboxChanged());
      await settle();
      expect(bloc.state.pendingCaptures, [capture]);
      bloc.add(AutoCaptureDismissed(capture));
      await settle();
      verify(() => inbox.dismiss(capture.id)).called(1);
      verifyNever(() => mockAdd.call(any()));
    });

    test(
      'uses one transaction ID after a failed confirmation and double tap',
      () async {
        final writes = <TransactionEntity>[];
        when(() => mockAdd.call(any())).thenAnswer((call) async {
          writes.add(call.positionalArguments.first as TransactionEntity);
          await settle();
          if (writes.length == 1) throw StateError('interrupted write');
        });
        final confirm = AutoCaptureConfirmed(
          capture,
          editedNote: 'edited',
          editedAmount: 9,
        );
        bloc.add(confirm);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        expect(pending, [capture]);
        bloc.add(confirm);
        bloc.add(confirm);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        expect(pending, isEmpty);
        expect(writes.map((t) => t.id), [
          capture.transactionId,
          capture.transactionId,
        ]);
        expect(writes.last.note, 'edited');
        expect(writes.last.amount, 9);
        verify(() => inbox.markSaved(capture.id)).called(1);
      },
    );

    test(
      'stale review from a different account cannot post or dismiss',
      () async {
        when(() => inbox.owner).thenReturn('another-user');
        bloc.add(AutoCaptureConfirmed(capture));
        bloc.add(AutoCaptureDismissed(capture));
        await settle();
        verifyNever(() => mockAdd.call(any()));
        verifyNever(() => inbox.dismiss(any()));
        expect(pending, [capture]);
      },
    );

    test('confirming a sample leaves the ledger untouched', () async {
      final sample = AutoCapturedTransaction(
        id: 'sample',
        owner: 'test-user',
        isSample: true,
        amount: 10,
        type: capture.type,
        note: 'sample',
        occurredAt: capture.occurredAt,
        sourceLabel: 'sample',
      );
      pending = [sample];
      bloc.add(AutoCaptureConfirmed(sample));
      await settle();
      verifyNever(() => mockAdd.call(any()));
      expect(pending, isEmpty);
    });
  });
}
