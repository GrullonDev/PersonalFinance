// test/core/services/transaction_linking_service_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/core/services/transaction_linking_service.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart';

class MockTransactionRepo extends Mock implements TransactionBackendRepository {}
class MockGoalRepo extends Mock implements GoalRepository {}
class MockDebtRepo extends Mock implements DebtRepository {}

TransactionBackend _tx({
  required String descripcion,
  required String tipo,
  required double monto,
}) => TransactionBackend(
  id: '1',
  tipo: tipo,
  monto: monto.toString(),
  descripcion: descripcion,
  fecha: DateTime(2026),
  categoriaId: '',
  esRecurrente: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  deviceId: 'dev',
  version: 1,
);

Goal _goal({required String nombre, double actual = 0, double objetivo = 100}) =>
    Goal(
      id: 'g1',
      nombre: nombre,
      montoObjetivo: objetivo.toString(),
      montoActual: actual.toString(),
      fechaLimite: DateTime(2027),
    );

Debt _debt({required String name, double balance = 500, double original = 500}) =>
    Debt(
      id: 'd1',
      name: name,
      currentBalance: balance,
      originalAmount: original,
      interestRate: 10,
      minimumPayment: 50,
      nextPaymentDate: DateTime(2026, 6),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      deviceId: 'dev',
      version: 1,
    );

void main() {
  late MockTransactionRepo txRepo;
  late MockGoalRepo goalRepo;
  late MockDebtRepo debtRepo;
  late TransactionLinkingService service;

  setUpAll(() {
    registerFallbackValue(_goal(nombre: 'fallback'));
    registerFallbackValue(_debt(name: 'fallback'));
  });

  setUp(() {
    txRepo = MockTransactionRepo();
    goalRepo = MockGoalRepo();
    debtRepo = MockDebtRepo();
    service = TransactionLinkingService(
      transactionRepo: txRepo,
      goalRepo: goalRepo,
      debtRepo: debtRepo,
    );
  });

  group('sumMatchingTransactions', () {
    test('returns 0 when no transactions match', () async {
      when(() => txRepo.list(tipo: 'ingreso'))
          .thenAnswer((_) async => Right([_tx(descripcion: 'uber eats', tipo: 'ingreso', monto: 50)]));

      final result = await service.sumMatchingTransactions('Viaje Europa', 'ingreso');
      expect(result, 0.0);
    });

    test('returns sum of matching transactions by keyword', () async {
      when(() => txRepo.list(tipo: 'ingreso')).thenAnswer((_) async => Right([
        _tx(descripcion: 'ahorro viaje', tipo: 'ingreso', monto: 100),
        _tx(descripcion: 'deposito viaje navidad', tipo: 'ingreso', monto: 200),
        _tx(descripcion: 'pago uber', tipo: 'ingreso', monto: 50),
      ]));

      final result = await service.sumMatchingTransactions('Viaje Europa', 'ingreso');
      expect(result, 300.0);
    });

    test('returns 0 when name has no keywords >= 3 chars', () async {
      final result = await service.sumMatchingTransactions('a b', 'ingreso');
      expect(result, 0.0);
      verifyNever(() => txRepo.list(tipo: any(named: 'tipo')));
    });

    test('matching is case-insensitive', () async {
      when(() => txRepo.list(tipo: 'gasto')).thenAnswer((_) async => Right([
        _tx(descripcion: 'TARJETA credito pago', tipo: 'gasto', monto: 35),
      ]));

      final result = await service.sumMatchingTransactions('Tarjeta de Crédito', 'gasto');
      expect(result, 35.0);
    });

    test('matching is accent-insensitive (crédito matches credito)', () async {
      when(() => txRepo.list(tipo: 'gasto')).thenAnswer((_) async => Right([
        _tx(descripcion: 'pago credito mensual', tipo: 'gasto', monto: 35),
      ]));

      final result = await service.sumMatchingTransactions('Tarjeta de Crédito', 'gasto');
      expect(result, 35.0);
    });

    test('returns 0 on repo failure', () async {
      when(() => txRepo.list(tipo: 'ingreso'))
          .thenAnswer((_) async => Left(ServerFailure(message: 'error')));

      final result = await service.sumMatchingTransactions('Meta', 'ingreso');
      expect(result, 0.0);
    });
  });

  group('processTransaction - goals', () {
    test('adds income amount to matching goal', () async {
      final goal = _goal(nombre: 'Viaje Europa', actual: 50, objetivo: 500);
      when(() => goalRepo.getGoals()).thenAnswer((_) async => Right([goal]));
      when(() => debtRepo.getDebts()).thenAnswer((_) async => const Right([]));
      when(() => goalRepo.updateGoal(any())).thenAnswer((_) async => Right(goal));

      await service.processTransaction(
        _tx(descripcion: 'deposito viaje', tipo: 'ingreso', monto: 100),
      );

      final captured = verify(() => goalRepo.updateGoal(captureAny())).captured;
      final updated = captured.first as Goal;
      expect(updated.actualAsDouble, closeTo(150.0, 0.01));
    });

    test('does not update already completed goal', () async {
      final goal = _goal(nombre: 'Viaje Europa', actual: 500, objetivo: 500);
      when(() => goalRepo.getGoals()).thenAnswer((_) async => Right([goal]));
      when(() => debtRepo.getDebts()).thenAnswer((_) async => const Right([]));

      await service.processTransaction(
        _tx(descripcion: 'deposito viaje', tipo: 'ingreso', monto: 100),
      );

      verifyNever(() => goalRepo.updateGoal(any()));
    });

    test('does not update goal when no keyword matches', () async {
      final goal = _goal(nombre: 'Vacaciones Playa');
      when(() => goalRepo.getGoals()).thenAnswer((_) async => Right([goal]));
      when(() => debtRepo.getDebts()).thenAnswer((_) async => const Right([]));

      await service.processTransaction(
        _tx(descripcion: 'pago supermercado', tipo: 'ingreso', monto: 50),
      );

      verifyNever(() => goalRepo.updateGoal(any()));
    });

    test('updates multiple matching goals independently', () async {
      final goal1 = _goal(nombre: 'Viaje Europa', actual: 50, objetivo: 500);
      final goal2 = _goal(nombre: 'Fondo Viaje', actual: 100, objetivo: 800);
      when(() => goalRepo.getGoals())
          .thenAnswer((_) async => Right([goal1, goal2]));
      when(() => debtRepo.getDebts()).thenAnswer((_) async => const Right([]));
      when(() => goalRepo.updateGoal(any()))
          .thenAnswer((_) async => Right(goal1));

      await service.processTransaction(
        _tx(descripcion: 'ahorro viaje', tipo: 'ingreso', monto: 75),
      );

      final captured = verify(() => goalRepo.updateGoal(captureAny())).captured;
      expect(captured.length, 2);
      final updated1 = captured[0] as Goal;
      final updated2 = captured[1] as Goal;
      expect(updated1.actualAsDouble, closeTo(125.0, 0.01));
      expect(updated2.actualAsDouble, closeTo(175.0, 0.01));
    });
  });

  group('processTransaction - debts', () {
    test('reduces debt balance when expense matches debt name', () async {
      final debt = _debt(name: 'Tarjeta de Credito', balance: 500);
      when(() => debtRepo.getDebts()).thenAnswer((_) async => Right([debt]));
      when(() => goalRepo.getGoals()).thenAnswer((_) async => const Right([]));
      when(() => debtRepo.updateDebt(any())).thenAnswer((_) async => Right(debt));

      await service.processTransaction(
        _tx(descripcion: 'pago tarjeta', tipo: 'gasto', monto: 35),
      );

      final captured = verify(() => debtRepo.updateDebt(captureAny())).captured;
      final updated = captured.first as Debt;
      expect(updated.currentBalance, closeTo(465.0, 0.01));
    });

    test('floors debt balance at 0', () async {
      final debt = _debt(name: 'Tarjeta', balance: 20);
      when(() => debtRepo.getDebts()).thenAnswer((_) async => Right([debt]));
      when(() => goalRepo.getGoals()).thenAnswer((_) async => const Right([]));
      when(() => debtRepo.updateDebt(any())).thenAnswer((_) async => Right(debt));

      await service.processTransaction(
        _tx(descripcion: 'tarjeta pago', tipo: 'gasto', monto: 100),
      );

      final captured = verify(() => debtRepo.updateDebt(captureAny())).captured;
      final updated = captured.first as Debt;
      expect(updated.currentBalance, 0.0);
    });

    test('does not update already paid-off debt', () async {
      final debt = _debt(name: 'Tarjeta', balance: 0);
      when(() => debtRepo.getDebts()).thenAnswer((_) async => Right([debt]));
      when(() => goalRepo.getGoals()).thenAnswer((_) async => const Right([]));

      await service.processTransaction(
        _tx(descripcion: 'tarjeta pago', tipo: 'gasto', monto: 50),
      );

      verifyNever(() => debtRepo.updateDebt(any()));
    });

    test('income transaction does not affect debts', () async {
      final debt = _debt(name: 'Tarjeta');
      when(() => debtRepo.getDebts()).thenAnswer((_) async => Right([debt]));
      when(() => goalRepo.getGoals()).thenAnswer((_) async => const Right([]));

      await service.processTransaction(
        _tx(descripcion: 'tarjeta ingreso', tipo: 'ingreso', monto: 50),
      );

      verifyNever(() => debtRepo.updateDebt(any()));
    });
  });
}
