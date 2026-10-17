import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/core/services/device_service.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:personal_finance/features/categories/data/services/category_auto_creator.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/quick_finance/data/sync/sync_manager.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/services/transaction_categorizer.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/add_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/delete_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/hydrate_current_user_transactions.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/update_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/watch_balance.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/watch_transactions.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_event.dart';

class _Add extends Mock implements AddTransaction {}

class _Update extends Mock implements UpdateTransaction {}

class _Delete extends Mock implements DeleteTransaction {}

class _Hydrate extends Mock implements HydrateCurrentUserTransactions {}

class _WatchBalance extends Mock implements WatchBalance {}

class _WatchTx extends Mock implements WatchTransactions {}

class _Sync extends Mock implements SyncManager {}

class _Auth extends Mock implements AuthDataSource {}

class _Goals extends Mock implements GoalRepository {}

class _Debts extends Mock implements DebtRepository {}

class _Device extends Mock implements DeviceService {}

class _Creator extends Mock implements CategoryAutoCreator {}

TransactionEntity _tx({
  required String id,
  required String note,
  String? category,
}) => TransactionEntity(
  id: id,
  userId: 'u',
  type: TransactionType.expense,
  amount: 20,
  note: note,
  categoryId: category,
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
  syncStatus: SyncStatus.synced,
  version: 1,
  deviceId: 'd',
);

void main() {
  late _Add add;
  late _Update update;
  late _Creator creator;
  late StreamController<List<TransactionEntity>> txStream;

  setUpAll(() {
    registerFallbackValue(_tx(id: 'x', note: 'x'));
    registerFallbackValue(TransactionType.expense);
  });

  QuickFinanceBloc build({Future<String?> Function(String)? ai}) {
    final auth = _Auth();
    when(() => auth.currentUserId).thenReturn('u');
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
    final sync = _Sync();
    when(() => sync.syncStream).thenAnswer((_) => const Stream.empty());
    final watchTx = _WatchTx();
    when(
      () => watchTx(userId: any(named: 'userId')),
    ).thenAnswer((_) => txStream.stream);
    final watchBal = _WatchBalance();
    when(
      () => watchBal(userId: any(named: 'userId')),
    ).thenAnswer((_) => const Stream.empty());
    final device = _Device();
    when(() => device.deviceId).thenReturn('d');
    final goals = _Goals();
    when(() => goals.getGoals()).thenAnswer((_) async => const Right([]));
    final debts = _Debts();
    when(() => debts.getDebts()).thenAnswer((_) async => const Right([]));

    return QuickFinanceBloc(
      addTransaction: add,
      deleteTransaction: _Delete(),
      hydrateCurrentUserTransactions: _Hydrate(),
      watchBalance: watchBal,
      watchTransactions: watchTx,
      updateTransaction: update,
      syncManager: sync,
      authDataSource: auth,
      goalRepository: goals,
      debtRepository: debts,
      deviceService: device,
      categorizer: TransactionCategorizer(ai: ai),
      categoryAutoCreator: creator,
    );
  }

  setUp(() {
    add = _Add();
    update = _Update();
    creator = _Creator();
    txStream = StreamController<List<TransactionEntity>>.broadcast();
    when(() => add(any())).thenAnswer((_) async {});
    when(() => update(any())).thenAnswer((_) async {});
    when(() => creator.ensure(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() => txStream.close());

  test(
    'un gasto con sólo el lugar se guarda con la categoría detectada',
    () async {
      final bloc = build();
      bloc.add(const RawEntrySubmitted('-45 Starbucks'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final saved =
          verify(() => add(captureAny())).captured.single as TransactionEntity;
      expect(saved.note, 'Starbucks');
      expect(saved.categoryId, 'comida');
      verify(() => creator.ensure('comida', TransactionType.expense)).called(1);
      await bloc.close();
    },
  );

  test('si las reglas no saben, la IA completa la categoría después', () async {
    final bloc = build(ai: (_) async => 'Entretenimiento');
    bloc.add(const RawEntrySubmitted('-80 Fiesta de Ana'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final saved =
        verify(() => add(captureAny())).captured.single as TransactionEntity;
    expect(saved.categoryId, isNull);
    final updated =
        verify(() => update(captureAny())).captured.single as TransactionEntity;
    expect(updated.id, saved.id);
    expect(updated.categoryId, 'entretenimiento');
    expect(updated.version, 2);
    await bloc.close();
  });

  test('la etiqueta #categoría del usuario tiene prioridad', () async {
    final bloc = build();
    bloc.add(const RawEntrySubmitted('-30 Starbucks #trabajo'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final saved =
        verify(() => add(captureAny())).captured.single as TransactionEntity;
    expect(saved.categoryId, 'trabajo');
    await bloc.close();
  });

  test('completa la categoría de los gastos viejos sin categoría', () async {
    final bloc = build();
    bloc.add(
      TransactionsObserved([
        _tx(id: '1', note: 'Uber'),
        _tx(id: '2', note: 'Paiz', category: 'supermercado'),
        _tx(id: '3', note: 'XYZ 123'),
      ]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final updated =
        verify(() => update(captureAny())).captured.cast<TransactionEntity>();
    expect(updated, hasLength(1));
    expect(updated.single.id, '1');
    expect(updated.single.categoryId, 'transporte');
    await bloc.close();
  });
}
