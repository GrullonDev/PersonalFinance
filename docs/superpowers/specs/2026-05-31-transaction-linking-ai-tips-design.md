# Design Spec: Transaction Linking & AI Tips for Free Users

**Date:** 2026-05-31
**Status:** Approved
**Scope:** Two independent fixes discovered during TestFlight testing on iPhone

---

## 1. Problem Statements

### 1.1 Goals and Debts Ignore Existing Transactions

When a user enters transactions first (e.g., "Tarjeta de crédito - $35 expense") and later creates a goal or debt with a related name (e.g., "Tarjeta de Crédito"), the goal/debt is created with `montoActual = 0` and `currentBalance = originalAmount` — ignoring all prior relevant transactions.

Additionally, as the user continues adding related transactions after creating the goal/debt, the goal/debt progress does not update automatically.

**Desired behavior:** The system automatically detects keyword matches between transaction descriptions and goal/debt names, pre-populates the initial amount at creation time, and updates progress on every new matching transaction.

### 1.2 AI Advisor Tips Not Visible to Free Plan Users

New users (Free plan by default) only see the empty-state dashboard until they add transactions. After adding transactions, the `DashboardLogic` is not refreshed automatically when the user returns to the dashboard, so `hasData` remains `false` and the "Asesor Financiero IA ✨" card never appears.

**Desired behavior:** As soon as the user adds their first transaction and returns to the dashboard, the AI advisor analyzes the data and displays a personalized tip — with no manual pull-to-refresh required. This works for all users regardless of plan.

---

## 2. Feature 1: Automatic Transaction → Goal/Debt Linking

### 2.1 New Service: `TransactionLinkingService`

**Location:** `lib/core/services/transaction_linking_service.dart`

Centralizes all keyword matching and auto-update logic. Injected via GetIt as a singleton.

**Responsibilities:**
- `Future<double> sumMatchingTransactions(String name, String type)` — scans all existing transactions and returns the total amount that matches the name keyword for the given type (income for goals, expense for debts).
- `Future<void> processTransaction(TransactionBackend transaction)` — called after every new transaction is saved. Checks all active goals and debts for keyword matches and updates them.

### 2.2 Keyword Matching Rules

- Matching is **case-insensitive** and **partial** (contains).
- A match requires at least one keyword from the goal/debt name to be 3+ characters long and present in the transaction's `descripcion`.
- **Goals:** matched against **income** transactions (`tipo == 'ingreso'`). Matching amounts are **added** to `montoActual`.
- **Debts:** matched against **expense** transactions (`tipo == 'gasto'`). Matching amounts **reduce** `currentBalance` (floored at 0).

**Example:**
- Debt name: `"Tarjeta de Crédito"` → keywords: `["tarjeta", "credito"]`
- Transaction description: `"pago tarjeta"` → match ✓ → reduces debt balance
- Transaction description: `"uber eats"` → no match ✗

### 2.3 Pre-population at Creation

**Goal form (`goals_crud_page.dart`):**
- Before displaying the dialog for a **new** goal, call `TransactionLinkingService.sumMatchingTransactions(name, 'ingreso')` using the name entered by the user.
- The `currentCtrl` (Monto actual) initial value is set to the matched sum instead of `'0'`.
- Since the name is needed first, matching is triggered **after** the user types the name and taps a "Detectar transacciones" button or on name field blur — not on every keystroke.

**Debt form (`add_debt_dialog.dart`):**
- After the user fills **both** the name field and the `originalAmount` field and moves focus away, call `sumMatchingTransactions(name, 'gasto')`.
- Both values are needed: `originalAmount` to compute the remaining balance, matched sum as paid amount.
- The matched sum is shown as a suggestion chip: `"Se detectaron $X en transacciones relacionadas. ¿Usar como saldo pagado?"`.
- If accepted: `currentBalance = max(0.0, originalAmount - matchedSum)`.
- If declined: `currentBalance` field remains editable and empty for manual input.

### 2.4 Auto-update on New Transactions

There are two save paths in the app that must both hook into the linking service:

1. **`AddTransactionLogic.addTransaction()`** — used by the legacy add-expense/income flows
2. **`AddTransactionModal`** (via `TransactionsBloc`)— the main modal FAB flow on the dashboard

Both paths call `processTransaction` after a successful save:

```dart
await GetIt.instance<TransactionLinkingService>().processTransaction(entity);
```

For the `TransactionsBloc` path, the hook is placed in the bloc's `_onAdd` handler after `repo.create()` succeeds.

`processTransaction` internally:
1. Loads all active goals via `GoalRepository.getGoals()`
2. Loads all active debts via `DebtRepository.getDebts()`
3. For each match, calls `GoalRepository.updateGoal()` or `DebtRepository.updateDebt()` with the updated amount
4. Errors are caught and logged silently — transaction save is never blocked by a linking failure

### 2.5 Data Flow Diagram

```
User saves transaction
  └─ AddTransactionLogic.addTransaction()
       └─ repo.create(entity) ✓
       └─ TransactionLinkingService.processTransaction(entity)
            ├─ GoalRepository.getGoals()
            │    └─ match found → GoalRepository.updateGoal(goal.copyWith(montoActual: newAmount))
            └─ DebtRepository.getDebts()
                 └─ match found → DebtRepository.updateDebt(debt.copyWith(currentBalance: newBalance))
```

### 2.6 Edge Cases

| Scenario | Behavior |
|----------|----------|
| No goals or debts exist | `processTransaction` exits immediately, no-op |
| Multiple goals match same transaction | Each matching goal is updated independently |
| Debt balance would go below 0 | `currentBalance` is floored at `0.0` |
| Transaction linking fails | Error is logged, transaction save is unaffected |
| Goal already completed (actual >= objetivo) | Skip update — goal stays at 100% |

---

## 3. Feature 2: AI Tips Auto-Visible After First Transaction

### 3.1 Root Cause

`DashboardPage` uses `ChangeNotifierProvider.create` which calls `logic.loadDashboardData()` once at mount. Navigation to add-transaction flows and back does not re-trigger this load. So after adding the first transaction, `DashboardLogic._expenses` and `_incomes` stay empty, `hasData = false`, and the AI card is never shown.

### 3.2 Solution: RouteAware Auto-Refresh

Register a `RouteObserver<ModalRoute<dynamic>>` as a singleton in GetIt and add it to `MaterialApp.navigatorObservers`. Convert `DashboardPage` to a `StatefulWidget` that implements `RouteAware`.

**Refresh triggers:**
- `didPush()` — when dashboard is first pushed onto the stack (initial load, already handled)
- `didPopNext()` — when the user pops a route on top of the dashboard (returns from adding a transaction, goal, or debt). This is the new trigger.

### 3.3 Implementation Points

**`lib/utils/injection_container.dart` (or app bootstrap):**
```dart
sl.registerSingleton<RouteObserver<ModalRoute<dynamic>>>(
  RouteObserver<ModalRoute<dynamic>>(),
);
```

**`MaterialApp` in `app.dart`:**
```dart
navigatorObservers: [sl<RouteObserver<ModalRoute<dynamic>>>()],
```

**`DashboardPage` (converted to StatefulWidget):**
```dart
class _DashboardPageState extends State<DashboardPage>
    with RouteAware {

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sl<RouteObserver<ModalRoute<dynamic>>>()
        .subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    sl<RouteObserver<ModalRoute<dynamic>>>().unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // User returned to dashboard from another screen
    context.read<DashboardLogic>().loadDashboardData();
  }
}
```

### 3.4 AI Tips Availability on Free Plan

No subscription gate is needed. `fetchPersonalizedTip()`, `fetchSpendingPrediction()`, and `fetchHealthScore()` in `DashboardLogic` are already called unconditionally inside `loadDashboardData()`. The `freeFeatures = {}` set in `subscription_constants.dart` controls paywall features (AI Chat, AI Reports pages), not the dashboard AI advisor card.

The dashboard AI advisor card is a **Free feature by design** — it shows personalized tips inline on the dashboard and is not gated behind a paywall.

### 3.5 User Flow After Fix

```
New user opens app
  → Dashboard empty state (no transactions yet) ✓ expected

User taps + → adds first transaction → returns to dashboard
  → didPopNext() fires → loadDashboardData() runs
  → hasData = true → dashboard content section shows
  → fetchPersonalizedTip() runs in background
  → "Asesor Financiero IA ✨" card appears with personalized tip
```

---

## 4. Files to Modify

### New Files
| File | Purpose |
|------|---------|
| `lib/core/services/transaction_linking_service.dart` | Core keyword matching + auto-update service |

### Modified Files
| File | Change |
|------|--------|
| `lib/utils/injection_container.dart` | Register `TransactionLinkingService` and `RouteObserver` |
| `lib/features/transactions/presentation/providers/add_transaction_logic.dart` | Call `TransactionLinkingService.processTransaction()` after save |
| `lib/features/transactions/presentation/bloc/transactions_bloc.dart` | Call `TransactionLinkingService.processTransaction()` after save in add handler |
| `lib/features/goals/presentation/pages/goals_crud_page.dart` | Pre-populate `currentCtrl` using matched transactions; add detect button |
| `lib/features/debts/presentation/widgets/add_debt_dialog.dart` | Show suggestion chip with matched amount |
| `lib/features/dashboard/presentation/pages/dashboard_page.dart` | Convert to StatefulWidget + RouteAware for auto-refresh |
| `app.dart` (or equivalent) | Add `RouteObserver` to `navigatorObservers` |

---

## 5. Out of Scope

- Linking transactions to goals/debts retroactively via a batch job
- UI to view which transactions are linked to a goal/debt
- Unlinking or excluding a transaction from a goal/debt
- AI Chat or AI Reports pages for Free plan users (remain Pro-only)
