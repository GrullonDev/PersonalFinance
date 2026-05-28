import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:personal_finance/core/services/notifications/notification_service.dart';
import 'package:personal_finance/core/services/notifications/local_notification_service.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_event.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/add_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/delete_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/hydrate_current_user_transactions.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/watch_balance.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/watch_transactions.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/update_transaction.dart';
import 'package:personal_finance/features/quick_finance/data/sync/sync_manager.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';

class MockLocalNotificationService extends Mock implements LocalNotificationService {}
class MockNotificationService extends Mock implements NotificationService {}

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

class FakeTransactionEntity extends Fake implements TransactionEntity {}

class FakeGoal extends Fake implements Goal {}

class FakeDebt extends Fake implements Debt {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTransactionEntity());
    registerFallbackValue(FakeGoal());
    registerFallbackValue(FakeDebt());
  });

  group('QuickFinanceBloc Goals & Debts Integration Tests', () {
    late QuickFinanceBloc bloc;
    late MockAddTransaction mockAddTransaction;
    late MockDeleteTransaction mockDeleteTransaction;
    late MockHydrateCurrentUserTransactions mockHydrateCurrentUserTransactions;
    late MockWatchBalance mockWatchBalance;
    late MockWatchTransactions mockWatchTransactions;
    late MockUpdateTransaction mockUpdateTransaction;
    late MockSyncManager mockSyncManager;
    late MockAuthDataSource mockAuthDataSource;
    late MockGoalRepository mockGoalRepository;
    late MockDebtRepository mockDebtRepository;

    setUp(() {
      mockAddTransaction = MockAddTransaction();
      mockDeleteTransaction = MockDeleteTransaction();
      mockHydrateCurrentUserTransactions = MockHydrateCurrentUserTransactions();
      mockWatchBalance = MockWatchBalance();
      mockWatchTransactions = MockWatchTransactions();
      mockUpdateTransaction = MockUpdateTransaction();
      mockSyncManager = MockSyncManager();
      mockAuthDataSource = MockAuthDataSource();
      mockGoalRepository = MockGoalRepository();
      mockDebtRepository = MockDebtRepository();

      bloc = QuickFinanceBloc(
        addTransaction: mockAddTransaction,
        deleteTransaction: mockDeleteTransaction,
        hydrateCurrentUserTransactions: mockHydrateCurrentUserTransactions,
        watchBalance: mockWatchBalance,
        watchTransactions: mockWatchTransactions,
        updateTransaction: mockUpdateTransaction,
        syncManager: mockSyncManager,
        authDataSource: mockAuthDataSource,
        goalRepository: mockGoalRepository,
        debtRepository: mockDebtRepository,
      );

      final mockNotificationService = MockNotificationService();
      final mockLocalNotificationService = MockLocalNotificationService();
      when(() => mockNotificationService.local).thenReturn(mockLocalNotificationService);
      when(() => mockLocalNotificationService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {});

      if (GetIt.instance.isRegistered<NotificationService>()) {
        GetIt.instance.unregister<NotificationService>();
      }
      GetIt.instance.registerSingleton<NotificationService>(mockNotificationService);

      when(() => mockAuthDataSource.currentUserId).thenReturn('test-user');
      when(() => mockAddTransaction.call(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      bloc.close();
      if (GetIt.instance.isRegistered<NotificationService>()) {
        GetIt.instance.unregister<NotificationService>();
      }
    });

    test(
      'should add amount to goal when "50 meta Ahorro Casa" is submitted',
      () async {
        // Arrange
        final goal = Goal(
          id: 'goal-1',
          nombre: 'Ahorro Casa',
          montoObjetivo: '1000',
          montoActual: '200',
          fechaLimite: DateTime(2027),
        );
        when(
          () => mockGoalRepository.getGoals(),
        ).thenAnswer((_) async => Right([goal]));
        when(
          () => mockGoalRepository.updateGoal(any()),
        ).thenAnswer((_) async => Right(goal));

        // Act
        bloc.add(const RawEntrySubmitted('50 meta Ahorro Casa'));

        // Wait for async processing in bloc to resolve
        await untilCalled(() => mockGoalRepository.updateGoal(any()));

        // Assert
        final capturedGoal =
            verify(
                  () => mockGoalRepository.updateGoal(captureAny()),
                ).captured.single
                as Goal;
        expect(capturedGoal.montoActual, '250.0');
      },
    );

    test(
      'should subtract amount from goal when "-30 meta Ahorro Casa" is submitted',
      () async {
        // Arrange
        final goal = Goal(
          id: 'goal-1',
          nombre: 'Ahorro Casa',
          montoObjetivo: '1000',
          montoActual: '200',
          fechaLimite: DateTime(2027),
        );
        when(
          () => mockGoalRepository.getGoals(),
        ).thenAnswer((_) async => Right([goal]));
        when(
          () => mockGoalRepository.updateGoal(any()),
        ).thenAnswer((_) async => Right(goal));

        // Act
        bloc.add(const RawEntrySubmitted('-30 meta Ahorro Casa'));

        // Wait
        await untilCalled(() => mockGoalRepository.updateGoal(any()));

        // Assert
        final capturedGoal =
            verify(
                  () => mockGoalRepository.updateGoal(captureAny()),
                ).captured.single
                as Goal;
        expect(capturedGoal.montoActual, '170.0');
      },
    );

    test(
      'should subtract amount from debt (abono) when "100 deuda Tarjeta" is submitted',
      () async {
        // Arrange
        final debt = Debt(
          id: 'debt-1',
          name: 'Tarjeta',
          currentBalance: 500,
          originalAmount: 1000,
          interestRate: 0,
          nextPaymentDate: DateTime(2027),
          minimumPayment: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deviceId: 'device-1',
          version: 1,
        );
        when(
          () => mockDebtRepository.getDebts(),
        ).thenAnswer((_) async => Right([debt]));
        when(
          () => mockDebtRepository.updateDebt(any()),
        ).thenAnswer((_) async => Right(debt));

        // Act
        bloc.add(const RawEntrySubmitted('100 deuda Tarjeta'));

        // Wait
        await untilCalled(() => mockDebtRepository.updateDebt(any()));

        // Assert
        final capturedDebt =
            verify(
                  () => mockDebtRepository.updateDebt(captureAny()),
                ).captured.single
                as Debt;
        expect(capturedDebt.currentBalance, 400.0);
      },
    );

    test(
      'should add amount to debt (increase debt) when "-100 deuda Tarjeta" is submitted',
      () async {
        // Arrange
        final debt = Debt(
          id: 'debt-1',
          name: 'Tarjeta',
          currentBalance: 500,
          originalAmount: 1000,
          interestRate: 0,
          nextPaymentDate: DateTime(2027),
          minimumPayment: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deviceId: 'device-1',
          version: 1,
        );
        when(
          () => mockDebtRepository.getDebts(),
        ).thenAnswer((_) async => Right([debt]));
        when(
          () => mockDebtRepository.updateDebt(any()),
        ).thenAnswer((_) async => Right(debt));

        // Act
        bloc.add(const RawEntrySubmitted('-100 deuda Tarjeta'));

        // Wait
        await untilCalled(() => mockDebtRepository.updateDebt(any()));

        // Assert
        final capturedDebt =
            verify(
                  () => mockDebtRepository.updateDebt(captureAny()),
                ).captured.single
                as Debt;
        expect(capturedDebt.currentBalance, 600.0);
      },
    );

    test(
      'should fallback to exact name matching when "150 Ahorro Casa" (no prefix) is submitted',
      () async {
        // Arrange
        final goal = Goal(
          id: 'goal-1',
          nombre: 'Ahorro Casa',
          montoObjetivo: '1000',
          montoActual: '200',
          fechaLimite: DateTime(2027),
        );
        when(
          () => mockGoalRepository.getGoals(),
        ).thenAnswer((_) async => Right([goal]));
        when(
          () => mockGoalRepository.updateGoal(any()),
        ).thenAnswer((_) async => Right(goal));

        // Act
        bloc.add(const RawEntrySubmitted('150 Ahorro Casa'));

        // Wait
        await untilCalled(() => mockGoalRepository.updateGoal(any()));

        // Assert
        final capturedGoal =
            verify(
                  () => mockGoalRepository.updateGoal(captureAny()),
                ).captured.single
                as Goal;
        expect(capturedGoal.montoActual, '350.0');
      },
    );

    test(
      'should fallback to single goal when "50 meta" is submitted and there is exactly one goal',
      () async {
        // Arrange
        final goal = Goal(
          id: 'goal-1',
          nombre: 'Ahorro Casa',
          montoObjetivo: '1000',
          montoActual: '200',
          fechaLimite: DateTime(2027),
        );
        when(
          () => mockGoalRepository.getGoals(),
        ).thenAnswer((_) async => Right([goal]));
        when(
          () => mockGoalRepository.updateGoal(any()),
        ).thenAnswer((_) async => Right(goal));

        // Act
        bloc.add(const RawEntrySubmitted('50 meta'));

        // Wait
        await untilCalled(() => mockGoalRepository.updateGoal(any()));

        // Assert
        final capturedGoal =
            verify(
                  () => mockGoalRepository.updateGoal(captureAny()),
                ).captured.single
                as Goal;
        expect(capturedGoal.montoActual, '250.0');
      },
    );

    test(
      'should NOT update any goal when "50 meta" is submitted and there are multiple goals',
      () async {
        // Arrange
        final goal1 = Goal(
          id: 'goal-1',
          nombre: 'Ahorro Casa',
          montoObjetivo: '1000',
          montoActual: '200',
          fechaLimite: DateTime(2027),
        );
        final goal2 = Goal(
          id: 'goal-2',
          nombre: 'Vacaciones',
          montoObjetivo: '500',
          montoActual: '100',
          fechaLimite: DateTime(2027),
        );
        when(
          () => mockGoalRepository.getGoals(),
        ).thenAnswer((_) async => Right([goal1, goal2]));

        // Act
        bloc.add(const RawEntrySubmitted('50 meta'));

        // Wait for a brief period to ensure no repository interaction is made
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Assert
        verifyNever(() => mockGoalRepository.updateGoal(any()));
      },
    );

    test(
      'should fallback to single debt when "100 deuda" is submitted and there is exactly one debt',
      () async {
        // Arrange
        final debt = Debt(
          id: 'debt-1',
          name: 'Tarjeta',
          currentBalance: 500,
          originalAmount: 1000,
          interestRate: 0,
          nextPaymentDate: DateTime(2027),
          minimumPayment: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deviceId: 'device-1',
          version: 1,
        );
        when(
          () => mockDebtRepository.getDebts(),
        ).thenAnswer((_) async => Right([debt]));
        when(
          () => mockDebtRepository.updateDebt(any()),
        ).thenAnswer((_) async => Right(debt));

        // Act
        bloc.add(const RawEntrySubmitted('100 deuda'));

        // Wait
        await untilCalled(() => mockDebtRepository.updateDebt(any()));

        // Assert
        final capturedDebt =
            verify(
                  () => mockDebtRepository.updateDebt(captureAny()),
                ).captured.single
                as Debt;
        expect(capturedDebt.currentBalance, 400.0);
      },
    );

    test(
      'should NOT update any debt when "100 deuda" is submitted and there are multiple debts',
      () async {
        // Arrange
        final debt1 = Debt(
          id: 'debt-1',
          name: 'Tarjeta',
          currentBalance: 500,
          originalAmount: 1000,
          interestRate: 0,
          nextPaymentDate: DateTime(2027),
          minimumPayment: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deviceId: 'device-1',
          version: 1,
        );
        final debt2 = Debt(
          id: 'debt-2',
          name: 'Prestamo',
          currentBalance: 800,
          originalAmount: 2000,
          interestRate: 0,
          nextPaymentDate: DateTime(2027),
          minimumPayment: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deviceId: 'device-1',
          version: 1,
        );
        when(
          () => mockDebtRepository.getDebts(),
        ).thenAnswer((_) async => Right([debt1, debt2]));

        // Act
        bloc.add(const RawEntrySubmitted('100 deuda'));

        // Wait for a brief period to ensure no repository interaction is made
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Assert
        verifyNever(() => mockDebtRepository.updateDebt(any()));
      },
    );

    test(
      'should trigger completion notification when goal is completed (reaches objective)',
      () async {
        // Arrange
        final goal = Goal(
          id: 'goal-1',
          nombre: 'Ahorro Casa',
          montoObjetivo: '1000',
          montoActual: '950',
          fechaLimite: DateTime(2027),
        );
        when(
          () => mockGoalRepository.getGoals(),
        ).thenAnswer((_) async => Right([goal]));
        when(
          () => mockGoalRepository.updateGoal(any()),
        ).thenAnswer((_) async => Right(goal));

        // Act
        bloc.add(const RawEntrySubmitted('50 meta'));

        // Wait
        await untilCalled(() => mockGoalRepository.updateGoal(any()));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        final notif = GetIt.instance<NotificationService>();
        verify(() => notif.local.showNotification(
              id: goal.id.hashCode,
              title: '🏆 ¡Meta Completada!',
              body: any(named: 'body'),
              payload: RoutePath.goalsCrud,
            )).called(1);
      },
    );

    test(
      'should trigger completion notification when debt is completed (reaches 0 balance)',
      () async {
        // Arrange
        final debt = Debt(
          id: 'debt-1',
          name: 'Tarjeta',
          currentBalance: 100,
          originalAmount: 1000,
          interestRate: 0,
          nextPaymentDate: DateTime(2027),
          minimumPayment: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deviceId: 'device-1',
          version: 1,
        );
        when(
          () => mockDebtRepository.getDebts(),
        ).thenAnswer((_) async => Right([debt]));
        when(
          () => mockDebtRepository.updateDebt(any()),
        ).thenAnswer((_) async => Right(debt));

        // Act
        bloc.add(const RawEntrySubmitted('100 deuda'));

        // Wait
        await untilCalled(() => mockDebtRepository.updateDebt(any()));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        final notif = GetIt.instance<NotificationService>();
        verify(() => notif.local.showNotification(
              id: debt.id.hashCode,
              title: '🎉 ¡Deuda Liquidada!',
              body: any(named: 'body'),
              payload: RoutePath.debts,
            )).called(1);
      },
    );

    test(
      'should discount debt when amount is less than minimum payment',
      () async {
        // Arrange
        final debt = Debt(
          id: 'debt-1',
          name: 'Tarjeta',
          currentBalance: 500,
          originalAmount: 1000,
          interestRate: 0,
          nextPaymentDate: DateTime(2027),
          minimumPayment: 200,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deviceId: 'device-1',
          version: 1,
        );
        when(
          () => mockDebtRepository.getDebts(),
        ).thenAnswer((_) async => Right([debt]));
        when(
          () => mockDebtRepository.updateDebt(any()),
        ).thenAnswer((_) async => Right(debt));

        // Act
        bloc.add(const RawEntrySubmitted('100 deuda Tarjeta'));

        // Wait
        await untilCalled(() => mockDebtRepository.updateDebt(any()));

        // Assert
        final capturedDebt =
            verify(() => mockDebtRepository.updateDebt(captureAny()))
                .captured
                .single as Debt;
        expect(capturedDebt.currentBalance, 400.0);
      },
    );

    test(
      'should discount debt when amount is greater than or equal to minimum payment',
      () async {
        // Arrange
        final debt = Debt(
          id: 'debt-1',
          name: 'Tarjeta',
          currentBalance: 500,
          originalAmount: 1000,
          interestRate: 0,
          nextPaymentDate: DateTime(2027),
          minimumPayment: 200,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deviceId: 'device-1',
          version: 1,
        );
        when(
          () => mockDebtRepository.getDebts(),
        ).thenAnswer((_) async => Right([debt]));
        when(
          () => mockDebtRepository.updateDebt(any()),
        ).thenAnswer((_) async => Right(debt));

        // Act
        bloc.add(const RawEntrySubmitted('300 deuda Tarjeta'));

        // Wait
        await untilCalled(() => mockDebtRepository.updateDebt(any()));

        // Assert
        final capturedDebt =
            verify(() => mockDebtRepository.updateDebt(captureAny()))
                .captured
                .single as Debt;
        expect(capturedDebt.currentBalance, 200.0);
      },
    );

    test(
      'should match and discount debt when using variations like "cuota Tarjeta", "pago de la Tarjeta", "abono a mi Tarjeta", "cuota minima de Tarjeta"',
      () async {
        final variations = [
          '300 cuota Tarjeta',
          '300 pago de la Tarjeta',
          '300 abono a mi Tarjeta',
          '300 cuota minima de Tarjeta',
        ];

        for (final input in variations) {
          // Arrange
          final debt = Debt(
            id: 'debt-1',
            name: 'Tarjeta',
            currentBalance: 500,
            originalAmount: 1000,
            interestRate: 0,
            nextPaymentDate: DateTime(2027),
            minimumPayment: 200,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            deviceId: 'device-1',
            version: 1,
          );
          
          final localMockDebtRepository = MockDebtRepository();
          when(() => localMockDebtRepository.getDebts()).thenAnswer((_) async => Right([debt]));
          when(() => localMockDebtRepository.updateDebt(any())).thenAnswer((_) async => Right(debt));

          final localBloc = QuickFinanceBloc(
            addTransaction: mockAddTransaction,
            deleteTransaction: mockDeleteTransaction,
            hydrateCurrentUserTransactions: mockHydrateCurrentUserTransactions,
            watchBalance: mockWatchBalance,
            watchTransactions: mockWatchTransactions,
            updateTransaction: mockUpdateTransaction,
            syncManager: mockSyncManager,
            authDataSource: mockAuthDataSource,
            goalRepository: mockGoalRepository,
            debtRepository: localMockDebtRepository,
          );

          // Act
          localBloc.add(RawEntrySubmitted(input));

          // Wait
          await untilCalled(() => localMockDebtRepository.updateDebt(any()));

          // Assert
          final capturedDebt =
              verify(() => localMockDebtRepository.updateDebt(captureAny()))
                  .captured
                  .single as Debt;
          expect(capturedDebt.currentBalance, 200.0);

          localBloc.close();
        }
      },
    );

    test(
      'should match and increase goal when using variations like "ahorro para la Ahorro Casa"',
      () async {
        // Arrange
        final goal = Goal(
          id: 'goal-1',
          nombre: 'Ahorro Casa',
          montoObjetivo: '1000',
          montoActual: '200',
          fechaLimite: DateTime(2027),
        );
        when(
          () => mockGoalRepository.getGoals(),
        ).thenAnswer((_) async => Right([goal]));
        when(
          () => mockGoalRepository.updateGoal(any()),
        ).thenAnswer((_) async => Right(goal));

        // Act
        bloc.add(const RawEntrySubmitted('100 ahorro para la Ahorro Casa'));

        // Wait
        await untilCalled(() => mockGoalRepository.updateGoal(any()));

        // Assert
        final capturedGoal =
            verify(() => mockGoalRepository.updateGoal(captureAny()))
                .captured
                .single as Goal;
        expect(capturedGoal.montoActual, '300.0');
      },
    );
  });
}
