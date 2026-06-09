# Transaction Linking & AI Tips Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automatically link transactions to goals/debts by keyword matching, and make the AI advisor tips appear on the dashboard as soon as a user adds their first transaction.

**Architecture:** A new `TransactionLinkingService` singleton handles all keyword matching and auto-updates goals/debts when transactions are saved. Both save paths (TransactionsBloc and AddTransactionLogic) call this service. The Dashboard page is upgraded to a RouteAware StatefulWidget that calls `loadDashboardData()` whenever the user navigates back to it.

**Tech Stack:** Flutter/Dart, GetIt (DI), flutter_bloc, dartz (Either), mocktail (tests)

---

## File Map

| File | Action | What changes |
|------|--------|--------------|
| `lib/core/services/transaction_linking_service.dart` | **Create** | New service: keyword matching + auto-update logic |
| `test/core/services/transaction_linking_service_test.dart` | **Create** | Unit tests for the service |
| `lib/utils/injection_container.dart` | **Modify** | Register `TransactionLinkingService` and `RouteObserver` |
| `lib/utils/app.dart` | **Modify** | Add `navigatorObservers` to `MaterialApp` |
| `lib/features/transactions/presentation/bloc/transactions_bloc.dart` | **Modify** | Call `processTransaction` in `_onCreate` after success |
| `lib/features/transactions/presentation/providers/add_transaction_logic.dart` | **Modify** | Call `processTransaction` in `addTransaction` after success |
| `lib/features/goals/presentation/pages/goals_crud_page.dart` | **Modify** | Detect-button + pre-populate `currentCtrl` from matched transactions |
| `lib/features/debts/presentation/widgets/add_debt_dialog.dart` | **Modify** | Suggestion chip: matched sum → auto-fill `currentBalance` |
| `lib/features/dashboard/presentation/pages/dashboard_page.dart` | **Modify** | Convert to StatefulWidget + RouteAware → auto-refresh on `didPopNext` |

---

## Task 1: Create TransactionLinkingService (with tests first)

**Files:**
- Create: `lib/core/services/transaction_linking_service.dart`
- Create: `test/core/services/transaction_linking_service_test.dart`

- [ ] **Step 1.1: Create test file with failing tests**

```dart
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
```

- [ ] **Step 1.2: Run tests — verify they fail (class not found)**

```bash
flutter test test/core/services/transaction_linking_service_test.dart
```

Expected output: compilation error — `TransactionLinkingService` not found.

- [ ] **Step 1.3: Create `TransactionLinkingService`**

```dart
// lib/core/services/transaction_linking_service.dart
import 'package:flutter/foundation.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart';

class TransactionLinkingService {
  TransactionLinkingService({
    required TransactionBackendRepository transactionRepo,
    required GoalRepository goalRepo,
    required DebtRepository debtRepo,
  })  : _transactionRepo = transactionRepo,
        _goalRepo = goalRepo,
        _debtRepo = debtRepo;

  final TransactionBackendRepository _transactionRepo;
  final GoalRepository _goalRepo;
  final DebtRepository _debtRepo;

  /// Returns 3+ character keywords from a name, lowercased.
  List<String> _keywords(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .split(RegExp(r'\s+'))
      .where((w) => w.length >= 3)
      .toList();

  /// True if the description contains any keyword from the list.
  bool _matches(String description, List<String> keywords) {
    final lower = description.toLowerCase();
    return keywords.any(lower.contains);
  }

  /// Sums all existing transactions of [tipo] whose description matches [name].
  /// Returns 0.0 on any error or no match.
  Future<double> sumMatchingTransactions(String name, String tipo) async {
    final keywords = _keywords(name);
    if (keywords.isEmpty) return 0.0;

    final result = await _transactionRepo.list(tipo: tipo);
    return result.fold(
      (_) => 0.0,
      (transactions) => transactions
          .where((t) => _matches(t.descripcion, keywords))
          .fold(0.0, (sum, t) => sum + (double.tryParse(t.monto) ?? 0.0)),
    );
  }

  /// Called after every new transaction is saved.
  /// Updates matching goals (income) or debts (expense) silently.
  Future<void> processTransaction(TransactionBackend transaction) async {
    try {
      final amount = double.tryParse(transaction.monto) ?? 0.0;
      if (amount <= 0) return;

      final keywords = _keywords(transaction.descripcion);
      if (keywords.isEmpty) return;

      if (transaction.tipo == 'ingreso') {
        await _updateMatchingGoals(keywords, amount);
      } else if (transaction.tipo == 'gasto') {
        await _updateMatchingDebts(keywords, amount);
      }
    } catch (e) {
      debugPrint('[TransactionLinkingService] processTransaction error: $e');
    }
  }

  Future<void> _updateMatchingGoals(
    List<String> txKeywords,
    double amount,
  ) async {
    final result = await _goalRepo.getGoals();
    result.fold((_) {}, (goals) async {
      for (final goal in goals) {
        if (goal.actualAsDouble >= goal.objetivoAsDouble) continue;
        final goalKeywords = _keywords(goal.nombre);
        if (!goalKeywords.any(txKeywords.contains)) continue;
        final newAmount = goal.actualAsDouble + amount;
        await _goalRepo.updateGoal(
          goal.copyWith(montoActual: newAmount.toStringAsFixed(2)),
        );
      }
    });
  }

  Future<void> _updateMatchingDebts(
    List<String> txKeywords,
    double amount,
  ) async {
    final result = await _debtRepo.getDebts();
    result.fold((_) {}, (debts) async {
      for (final debt in debts) {
        if (debt.currentBalance <= 0) continue;
        final debtKeywords = _keywords(debt.name);
        if (!debtKeywords.any(txKeywords.contains)) continue;
        final newBalance =
            (debt.currentBalance - amount).clamp(0.0, double.infinity);
        await _debtRepo.updateDebt(debt.copyWith(currentBalance: newBalance));
      }
    });
  }
}
```

- [ ] **Step 1.4: Run tests — verify they pass**

```bash
flutter test test/core/services/transaction_linking_service_test.dart --reporter=expanded
```

Expected: all tests PASS. Fix any failures before continuing.

- [ ] **Step 1.5: Commit**

```bash
git add lib/core/services/transaction_linking_service.dart \
        test/core/services/transaction_linking_service_test.dart
git commit -m "feat: add TransactionLinkingService with keyword matching"
```

---

## Task 2: Register TransactionLinkingService in GetIt

**Files:**
- Modify: `lib/utils/injection_container.dart`

- [ ] **Step 2.1: Add import and registration**

Open `lib/utils/injection_container.dart`. Add this import near the other service imports (around line 57-75):

```dart
import 'package:personal_finance/core/services/transaction_linking_service.dart';
```

Then inside `initDependencies()`, add this block **after** the `TransactionBackendRepository`, `GoalRepository`, and `DebtRepository` registrations (they are all `registerLazySingleton` — search for `DebtRepository` to find the right location):

```dart
// TransactionLinkingService
if (!getIt.isRegistered<TransactionLinkingService>()) {
  getIt.registerLazySingleton<TransactionLinkingService>(
    () => TransactionLinkingService(
      transactionRepo: getIt<backend_tx_repo.TransactionBackendRepository>(),
      goalRepo: getIt<GoalRepository>(),
      debtRepo: getIt<DebtRepository>(),
    ),
  );
}
```

- [ ] **Step 2.2: Verify it compiles**

```bash
flutter analyze lib/utils/injection_container.dart
```

Expected: no errors. Fix any import issues.

- [ ] **Step 2.3: Commit**

```bash
git add lib/utils/injection_container.dart
git commit -m "chore: register TransactionLinkingService in GetIt"
```

---

## Task 3: Hook TransactionsBloc to call processTransaction

**Files:**
- Modify: `lib/features/transactions/presentation/bloc/transactions_bloc.dart`

- [ ] **Step 3.1: Add import**

At the top of `transactions_bloc.dart`, add:

```dart
import 'package:get_it/get_it.dart';
import 'package:personal_finance/core/services/transaction_linking_service.dart';
```

- [ ] **Step 3.2: Update `_onCreate` handler**

Find `_onCreate` (around line 134). Replace the entire method with:

```dart
Future<void> _onCreate(
  TransactionCreate e,
  Emitter<TransactionsState> emit,
) async {
  emit(state.copyWith(loading: true));
  final Either<Failure, TransactionBackend> r = await _repo.create(e.payload);
  r.fold(
    (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
    (TransactionBackend t) {
      emit(
        state.copyWith(
          loading: false,
          items: <TransactionBackend>[t, ...state.items],
        ),
      );
      // Non-blocking: process linking after successful save
      GetIt.instance<TransactionLinkingService>()
          .processTransaction(t)
          .ignore();
    },
  );
}
```

- [ ] **Step 3.3: Analyze**

```bash
flutter analyze lib/features/transactions/presentation/bloc/transactions_bloc.dart
```

Expected: no errors.

- [ ] **Step 3.4: Commit**

```bash
git add lib/features/transactions/presentation/bloc/transactions_bloc.dart
git commit -m "feat: trigger TransactionLinkingService on TransactionCreate"
```

---

## Task 4: Hook AddTransactionLogic to call processTransaction

**Files:**
- Modify: `lib/features/transactions/presentation/providers/add_transaction_logic.dart`

- [ ] **Step 4.1: Add import**

```dart
import 'package:personal_finance/core/services/transaction_linking_service.dart';
```

- [ ] **Step 4.2: Update `addTransaction` method**

Find the line `result.fold((failure) => throw Exception(failure.message), (_) => null);` (around line 70) and replace it with:

```dart
result.fold(
  (failure) => throw Exception(failure.message),
  (_) {
    // Non-blocking: link transaction to matching goals/debts
    GetIt.instance<TransactionLinkingService>()
        .processTransaction(entity)
        .ignore();
  },
);
```

- [ ] **Step 4.3: Analyze**

```bash
flutter analyze lib/features/transactions/presentation/providers/add_transaction_logic.dart
```

Expected: no errors.

- [ ] **Step 4.4: Commit**

```bash
git add lib/features/transactions/presentation/providers/add_transaction_logic.dart
git commit -m "feat: trigger TransactionLinkingService on AddTransactionLogic save"
```

---

## Task 5: Pre-populate Goal form with matched transactions

**Files:**
- Modify: `lib/features/goals/presentation/pages/goals_crud_page.dart`

- [ ] **Step 5.1: Add import**

Add at the top of the file:

```dart
import 'package:get_it/get_it.dart';
import 'package:personal_finance/core/services/transaction_linking_service.dart';
```

- [ ] **Step 5.2: Replace `_openDialog` content block to support detection**

Inside `_openDialog` in `_GoalsViewState`, find these lines (around line 479):

```dart
final TextEditingController currentCtrl = TextEditingController(
  text: goal?.actualAsDouble.toStringAsFixed(2) ?? '0',
);
```

Replace with:

```dart
final TextEditingController currentCtrl = TextEditingController(
  text: goal?.actualAsDouble.toStringAsFixed(2) ?? '0',
);
bool isDetecting = false;
```

- [ ] **Step 5.3: Wrap dialog content with StatefulBuilder**

Find the `builder:` inside `showDialog` (around line 492). It currently looks like:

```dart
builder:
    (BuildContext context) => AlertDialog(
```

Replace the entire builder function signature (just the outer wrapper) to use `StatefulBuilder`:

```dart
builder: (BuildContext context) => StatefulBuilder(
  builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
```

And close the `StatefulBuilder` **after** the closing `)` of `AlertDialog(...)`:
```dart
  ),  // close AlertDialog
),   // close StatefulBuilder
```

> **Note:** The entire `AlertDialog(...)` block becomes the child of `StatefulBuilder`. Only the wrapping changes — the content of `AlertDialog` stays the same.

- [ ] **Step 5.4: Add "Detectar" button next to name field inside the dialog**

In the dialog's `Column` children, after the name `TextFormField` and before the first `SizedBox(height: 12)`, insert:

```dart
if (goal == null) // Only show for new goals
  Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: isDetecting
          ? null
          : () async {
              final name = nameCtrl.text.trim();
              if (name.length < 3) return;
              setDialogState(() => isDetecting = true);
              try {
                final matched = await GetIt.instance<TransactionLinkingService>()
                    .sumMatchingTransactions(name, 'ingreso');
                if (matched > 0) {
                  currentCtrl.text = matched.toStringAsFixed(2);
                }
              } finally {
                setDialogState(() => isDetecting = false);
              }
            },
      icon: isDetecting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.search, size: 16),
      label: const Text('Detectar transacciones', style: TextStyle(fontSize: 12)),
    ),
  ),
```

- [ ] **Step 5.5: Analyze**

```bash
flutter analyze lib/features/goals/presentation/pages/goals_crud_page.dart
```

Expected: no errors. Fix any bracket/scope issues from the StatefulBuilder wrapping.

- [ ] **Step 5.6: Manual test**

Run the app. Go to Metas → Nueva meta. Type a name that matches an existing transaction. Tap "Detectar transacciones". Verify "Monto actual" gets pre-filled.

- [ ] **Step 5.7: Commit**

```bash
git add lib/features/goals/presentation/pages/goals_crud_page.dart
git commit -m "feat: pre-populate goal current amount from matched transactions"
```

---

## Task 6: Debt form — suggestion chip for matched amount

**Files:**
- Modify: `lib/features/debts/presentation/widgets/add_debt_dialog.dart`

- [ ] **Step 6.1: Add import**

```dart
import 'package:get_it/get_it.dart';
import 'package:personal_finance/core/services/transaction_linking_service.dart';
```

- [ ] **Step 6.2: Add state variables to `_AddDebtDialogState`**

In `_AddDebtDialogState`, add two fields after the existing controllers:

```dart
double? _detectedPaymentAmount;
bool _isDetecting = false;
```

- [ ] **Step 6.3: Add `_detectMatchingTransactions` method**

Add this method inside `_AddDebtDialogState`, before `_submit`:

```dart
Future<void> _detectMatchingTransactions() async {
  final name = _nameController.text.trim();
  final original = double.tryParse(_amountController.text.trim());
  if (name.length < 3 || original == null || original <= 0) return;

  setState(() => _isDetecting = true);
  try {
    final matched = await GetIt.instance<TransactionLinkingService>()
        .sumMatchingTransactions(name, 'gasto');
    if (matched > 0 && mounted) {
      setState(() => _detectedPaymentAmount = matched);
    }
  } finally {
    if (mounted) setState(() => _isDetecting = false);
  }
}
```

- [ ] **Step 6.4: Trigger detection when `originalAmount` field loses focus**

Wrap the `_amountController` `TextFormField` with a `Focus` widget. Replace:

```dart
TextFormField(
  controller: _amountController,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
    labelText: 'Monto Original (Deuda Inicial)',
    border: OutlineInputBorder(),
  ),
```

With:

```dart
Focus(
  onFocusChange: (hasFocus) {
    if (!hasFocus && !_isEditing) _detectMatchingTransactions();
  },
  child: TextFormField(
    controller: _amountController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      labelText: 'Monto Original (Deuda Inicial)',
      border: OutlineInputBorder(),
    ),
```

And close the `Focus` widget after the `TextFormField`'s closing `)`:

```dart
  ),  // close TextFormField
),    // close Focus
```

- [ ] **Step 6.5: Show suggestion chip below the `currentBalance` field**

After the `_balanceController` `TextFormField` block and before its closing `SizedBox(height: 16)`, insert:

```dart
if (_isDetecting)
  const Padding(
    padding: EdgeInsets.only(top: 6),
    child: Row(
      children: [
        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 8),
        Text('Buscando transacciones...', style: TextStyle(fontSize: 12)),
      ],
    ),
  ),
if (!_isDetecting && _detectedPaymentAmount != null && _detectedPaymentAmount! > 0)
  Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Se detectaron \$${_detectedPaymentAmount!.toStringAsFixed(2)} en transacciones relacionadas.',
            style: const TextStyle(fontSize: 12, color: Colors.green),
          ),
        ),
        TextButton(
          onPressed: () {
            final original = double.tryParse(_amountController.text.trim()) ?? 0;
            final balance = (original - _detectedPaymentAmount!).clamp(0.0, double.infinity);
            _balanceController.text = balance.toStringAsFixed(2);
            setState(() => _detectedPaymentAmount = null);
          },
          child: const Text('Usar', style: TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: () => setState(() => _detectedPaymentAmount = null),
          child: const Text('Ignorar', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ],
    ),
  ),
```

- [ ] **Step 6.6: Analyze**

```bash
flutter analyze lib/features/debts/presentation/widgets/add_debt_dialog.dart
```

Expected: no errors.

- [ ] **Step 6.7: Manual test**

Run the app. Go to Deudas → Agregar deuda. Enter a name matching existing transactions, then enter the original amount and move focus away. Verify the suggestion chip appears. Tap "Usar" and verify `currentBalance` is set correctly.

- [ ] **Step 6.8: Commit**

```bash
git add lib/features/debts/presentation/widgets/add_debt_dialog.dart
git commit -m "feat: show matched transactions suggestion when creating a debt"
```

---

## Task 7: Register RouteObserver and wire to MaterialApp

**Files:**
- Modify: `lib/utils/injection_container.dart`
- Modify: `lib/utils/app.dart`

- [ ] **Step 7.1: Register RouteObserver in injection_container.dart**

Add this import near the Flutter imports at the top:

```dart
import 'package:flutter/material.dart' show RouteObserver, ModalRoute;
```

Add this registration block **anywhere** inside `initDependencies()` (e.g., right after the existing `NavigationService` registration):

```dart
// RouteObserver — used by DashboardPage to auto-refresh on navigation return
if (!getIt.isRegistered<RouteObserver<ModalRoute<dynamic>>>()) {
  getIt.registerSingleton<RouteObserver<ModalRoute<dynamic>>>(
    RouteObserver<ModalRoute<dynamic>>(),
  );
}
```

- [ ] **Step 7.2: Add `navigatorObservers` to MaterialApp in app.dart**

Open `lib/utils/app.dart`. Find the `MaterialApp(` widget (around line 105). Find the line `onGenerateRoute: RouteSwitch.generateRoute,` and add `navigatorObservers` right before it:

```dart
navigatorObservers: [
  getIt<RouteObserver<ModalRoute<dynamic>>>(),
],
onGenerateRoute: RouteSwitch.generateRoute,
```

- [ ] **Step 7.3: Analyze both files**

```bash
flutter analyze lib/utils/injection_container.dart lib/utils/app.dart
```

Expected: no errors.

- [ ] **Step 7.4: Commit**

```bash
git add lib/utils/injection_container.dart lib/utils/app.dart
git commit -m "chore: register RouteObserver and wire to MaterialApp navigatorObservers"
```

---

## Task 8: Convert DashboardPage to RouteAware StatefulWidget

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/dashboard_page.dart`

- [ ] **Step 8.1: Add import**

Add at the top of `dashboard_page.dart`:

```dart
import 'package:personal_finance/utils/injection_container.dart';
```

- [ ] **Step 8.2: Convert `DashboardPage` to StatefulWidget**

Find the current class definition:

```dart
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<DashboardLogic>(
    create: (context) {
      final logic = getIt<DashboardLogic>();
      logic.loadDashboardData();
      return logic;
    },
    child: const _DashboardContent(),
  );
}
```

Replace it entirely with:

```dart
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  late final RouteObserver<ModalRoute<dynamic>> _routeObserver;

  @override
  void initState() {
    super.initState();
    _routeObserver = getIt<RouteObserver<ModalRoute<dynamic>>>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      _routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called when the user pops a route on top of this one (returns to dashboard).
  @override
  void didPopNext() {
    context.read<DashboardLogic>().loadDashboardData();
  }

  @override
  Widget build(BuildContext context) => const _DashboardContent();
}
```

> **Note:** `DashboardLogic` is already provided globally in `MyApp` via `ChangeNotifierProvider<DashboardLogic>`, so `context.read<DashboardLogic>()` works without a local provider. The local `ChangeNotifierProvider` wrapper that previously called `loadDashboardData()` at creation is removed — the global provider in `MyApp` already holds the instance, and `loadDashboardData()` is called via `didPopNext()` on return, and should also be called once on first load.

- [ ] **Step 8.3: Trigger initial load on first display**

In the `build()` method, add a `didPush` override to load data when the route is first pushed:

```dart
@override
void didPush() {
  context.read<DashboardLogic>().loadDashboardData();
}
```

Add this method inside `_DashboardPageState`, alongside `didPopNext`.

- [ ] **Step 8.4: Analyze**

```bash
flutter analyze lib/features/dashboard/presentation/pages/dashboard_page.dart
```

Expected: no errors. The `RouteAware` mixin is from `package:flutter/material.dart` — no extra import needed.

- [ ] **Step 8.5: Manual end-to-end test**

Run the app on device/simulator:

1. Open app as a new user (no transactions)
2. Verify dashboard shows empty state (no AI card) ✓
3. Tap + → add a transaction (any amount, any description)
4. Return to dashboard
5. Verify the dashboard reloads — data appears
6. Verify "Asesor Financiero IA ✨" card appears within a few seconds with a personalized tip

- [ ] **Step 8.6: Commit**

```bash
git add lib/features/dashboard/presentation/pages/dashboard_page.dart
git commit -m "feat: dashboard auto-refreshes on return via RouteAware"
```

---

## Task 9: End-to-End Integration Test

- [ ] **Step 9.1: Run full test suite**

```bash
flutter test
```

Expected: all existing tests pass. Fix any regressions.

- [ ] **Step 9.2: Run analyzer on all modified files**

```bash
flutter analyze lib/
```

Expected: no errors (warnings acceptable if pre-existing).

- [ ] **Step 9.3: Manual integration test — full linking flow**

Scenario: Transaction → Debt linking

1. Add a transaction: type=gasto, description="pago tarjeta visa", amount=$50
2. Create a debt: name="Tarjeta Visa", originalAmount=$500
3. Move focus away from originalAmount field
4. Verify suggestion chip appears: "Se detectaron $50.00..."
5. Tap "Usar" → verify currentBalance field shows $450.00
6. Save the debt
7. Add another transaction: type=gasto, description="tarjeta visa cuota", amount=$100
8. Go to Deudas page → refresh
9. Verify "Tarjeta Visa" currentBalance is now $350.00

Scenario: Transaction → Goal linking

1. Add a transaction: type=ingreso, description="ahorro viaje europa", amount=$200
2. Create a goal: name="Viaje Europa", target=$1000
3. Tap "Detectar transacciones" → verify "Monto actual" shows $200.00
4. Save the goal
5. Add another transaction: type=ingreso, description="deposito viaje", amount=$150
6. Go to Metas page → refresh
7. Verify "Viaje Europa" montoActual is now $350.00

- [ ] **Step 9.4: Final commit**

```bash
git add .
git commit -m "feat: complete transaction linking and AI tips auto-refresh

- TransactionLinkingService: keyword matching for goals and debts
- Auto-update goals/debts on every new transaction save
- Pre-populate goal current amount from matched transactions
- Debt suggestion chip with auto-fill from matched payments
- Dashboard auto-refresh via RouteAware (AI tips visible after first transaction)"
```
