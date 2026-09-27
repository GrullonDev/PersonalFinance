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

// Mocks
class MockAddTransaction extends Mock implements AddTransaction {}
class MockDeleteTransaction extends Mock implements DeleteTransaction {}
class MockHydrateCurrentUserTransactions extends Mock implements HydrateCurrentUserTransactions {}
class MockWatchBalance extends Mock implements WatchBalance {}
class MockWatchTransactions extends Mock implements WatchTransactions {}
class MockUpdateTransaction extends Mock implements UpdateTransaction {}
class MockSyncManager extends Mock implements SyncManager {}
class MockAuthDataSource extends Mock implements AuthDataSource {}
class MockGoalRepository extends Mock implements GoalRepository {}
class MockDebtRepository extends Mock implements DebtRepository {}
class MockDeviceService extends Mock implements DeviceService {}
class MockNotificationService extends Mock implements NotificationService {}
class MockLocalNotificationService extends Mock implements LocalNotificationService {}

QuickFinanceBloc _buildBloc({required MockAddTransaction mockAdd}) {
  final mockAuth = MockAuthDataSource();
  when(() => mockAuth.currentUserId).thenReturn('test-user');
  when(() => mockAuth.authStateChanges).thenAnswer((_) => Stream.empty());

  final mockSync = MockSyncManager();
  when(() => mockSync.syncStream).thenAnswer((_) => Stream.empty());

  final mockWatchTx = MockWatchTransactions();
  when(() => mockWatchTx(userId: any(named: 'userId'))).thenAnswer((_) => Stream.empty());

  final mockWatchBal = MockWatchBalance();
  when(() => mockWatchBal(userId: any(named: 'userId'))).thenAnswer((_) => Stream.empty());

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

    test('AutoCaptureReceived is equatable', () {
      final e1 = AutoCaptureReceived(capture);
      final e2 = AutoCaptureReceived(capture);
      expect(e1, equals(e2));
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
    late MockNotificationService mockNotif;
    late MockLocalNotificationService mockLocalNotif;

    setUp(() {
      mockAdd = MockAddTransaction();
      mockNotif = MockNotificationService();
      mockLocalNotif = MockLocalNotificationService();

      when(() => mockNotif.local).thenReturn(mockLocalNotif);
      when(
        () => mockLocalNotif.showNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      if (GetIt.instance.isRegistered<NotificationService>()) {
        GetIt.instance.unregister<NotificationService>();
      }
      GetIt.instance.registerSingleton<NotificationService>(mockNotif);

      bloc = _buildBloc(mockAdd: mockAdd);
    });

    tearDown(() {
      bloc.close();
      if (GetIt.instance.isRegistered<NotificationService>()) {
        GetIt.instance.unregister<NotificationService>();
      }
    });

    test('AutoCaptureReceived appends to pendingCaptures', () async {
      bloc.add(AutoCaptureReceived(capture));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.pendingCaptures, [capture]);
    });

    test('two AutoCaptureReceived events queue both captures', () async {
      final capture2 = AutoCapturedTransaction(
        type: TransactionType.expense,
        amount: 30.0,
        note: 'KFC',
        occurredAt: DateTime(2026, 9, 25),
        sourceLabel: 'Google Wallet',
      );
      bloc.add(AutoCaptureReceived(capture));
      bloc.add(AutoCaptureReceived(capture2));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.pendingCaptures.length, 2);
    });

    test('AutoCaptureDismissed removes from pendingCaptures without saving', () async {
      bloc.add(AutoCaptureReceived(capture));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(AutoCaptureDismissed(capture));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.pendingCaptures, isEmpty);
      verifyNever(() => mockAdd.call(any()));
    });

    test('AutoCaptureConfirmed removes from pendingCaptures', () async {
      when(() => mockAdd.call(any())).thenAnswer((_) async {});

      bloc.add(AutoCaptureReceived(capture));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(AutoCaptureConfirmed(capture));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.pendingCaptures, isEmpty);
    });

    test('AutoCaptureConfirmed calls addTransaction', () async {
      when(() => mockAdd.call(any())).thenAnswer((_) async {});

      bloc.add(AutoCaptureReceived(capture));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(AutoCaptureConfirmed(capture));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(() => mockAdd.call(any())).called(1);
    });

    test('AutoCaptureConfirmed with editedNote passes edited note to addTransaction', () async {
      TransactionEntity? savedEntity;
      when(() => mockAdd.call(any())).thenAnswer((inv) async {
        savedEntity = inv.positionalArguments.first as TransactionEntity;
      });

      bloc.add(AutoCaptureReceived(capture));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(AutoCaptureConfirmed(capture, editedNote: 'KFC'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(savedEntity?.note, 'KFC');
    });

    test('AutoCaptureConfirmed with editedAmount passes edited amount to addTransaction', () async {
      TransactionEntity? savedEntity;
      when(() => mockAdd.call(any())).thenAnswer((inv) async {
        savedEntity = inv.positionalArguments.first as TransactionEntity;
      });

      bloc.add(AutoCaptureReceived(capture));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(AutoCaptureConfirmed(capture, editedAmount: 99.99));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(savedEntity?.amount, 99.99);
    });
  });
}
