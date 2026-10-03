# Auto-Capture Confirmation UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a review-before-save confirmation bottom sheet for auto-captured payments, plus Android notification access onboarding and iOS Shortcuts setup guide.

**Architecture:** Extend `QuickFinanceState` with a `pendingCaptures` queue and two setup flags; add three new events; wire new handlers in `QuickFinanceBloc` so auto-captures pause for user review; add three bottom sheet widgets driven by `BlocListener` in `QuickFinanceHomePage`.

**Tech Stack:** Flutter BLoC (`flutter_bloc`), `showModalBottomSheet`, `SharedPreferences`, `dart:io` for platform check.

**Spec:** `docs/superpowers/specs/2026-09-25-auto-capture-confirmation-ui-design.md`

---

## Global Constraints

- All UI text in Spanish (matches existing app language).
- Follow existing widget patterns: `CupertinoButton`/`ElevatedButton` for actions, app theme colours.
- `AutoCapturedTransaction` is immutable; never mutate it — remove from list by value equality.
- Bottom sheets are modal — only one open at a time; queue drains one entry per dismiss/confirm.
- SharedPreferences keys must be namespaced: `auto_capture_notification_suppress_until`, `auto_capture_shortcuts_setup_done`.
- Platform guard all Android-only code with `Platform.isAndroid`; iOS-only with `Platform.isIOS`.
- No new DI registrations required — `AutoCaptureService` is already registered.

## Review Focus

- **Rapid-fire captures:** two payments arrive within seconds — only one bottom sheet should be visible; second queues behind first. Test: `pendingCaptures` length reaches 2, then each confirm reduces it by 1.
- **Dismiss without save:** dismissed transaction must never be stored. Test: `AutoCaptureDismissed` does not call `addTransaction` use case.
- **Edited fields survive confirmation:** user changes note and category in the sheet — those edits must reach `AddTransactionRequested`. Test: `AutoCaptureConfirmed` with `editedNote`/`editedCategoryId` maps correctly to the event.
- **Android suppress window:** tapping "Not now" on the permission sheet must suppress it for 7 days, not permanently. Test: SharedPreferences key `auto_capture_notification_suppress_until` is set to ~7 days from now.
- **iOS setup flag persistence:** tapping "Got it" sets the done flag; "Remind me later" does not. Test: SharedPreferences key `auto_capture_shortcuts_setup_done` is set only on "Got it".

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `lib/features/quick_finance/presentation/bloc/quick_finance_event.dart` | Add 3 new events |
| Modify | `lib/features/quick_finance/presentation/bloc/quick_finance_state.dart` | Add `pendingCaptures`, `needsNotificationAccess`, `needsShortcutsSetup` |
| Modify | `lib/features/quick_finance/presentation/bloc/quick_finance_bloc.dart` | Wire new handlers; move notification to confirm path; add startup permission checks |
| Modify | `lib/features/quick_finance/presentation/pages/quick_finance_home_page.dart` | `BlocListener` drives bottom sheets |
| Create | `lib/features/auto_capture/presentation/auto_capture_bottom_sheet.dart` | Confirmation sheet UI |
| Create | `lib/features/auto_capture/presentation/notification_access_bottom_sheet.dart` | Android permission sheet UI |
| Create | `lib/features/auto_capture/presentation/shortcuts_setup_bottom_sheet.dart` | iOS Shortcuts guide sheet UI |
| Modify | `test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart` | Unit tests for new BLoC behaviour |

---

### Task 1: Extend events and state

**Files:**
- Modify: `lib/features/quick_finance/presentation/bloc/quick_finance_event.dart`
- Modify: `lib/features/quick_finance/presentation/bloc/quick_finance_state.dart`
- Test: `test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart`

**Interfaces:**
- Produces:
  - `AutoCaptureReceived(AutoCapturedTransaction capture)` event
  - `AutoCaptureConfirmed(AutoCapturedTransaction capture, {String? editedNote, String? editedCategoryId})` event
  - `AutoCaptureDismissed(AutoCapturedTransaction capture)` event
  - `QuickFinanceState` gains: `List<AutoCapturedTransaction> pendingCaptures`, `bool needsNotificationAccess`, `bool needsShortcutsSetup`

- [ ] **Step 1: Write failing state tests**

Create `test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_event.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_state.dart';
import 'package:personal_finance/core/constants/enums.dart';

void main() {
  group('QuickFinanceState pendingCaptures', () {
    final capture = AutoCapturedTransaction(
      type: TransactionType.expense,
      amount: 50.0,
      note: 'McDonald\'s',
      occurredAt: DateTime(2026, 9, 25),
      sourceLabel: 'Google Wallet',
      category: 'comida',
    );

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
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
fvm flutter test test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart
```
Expected: compilation error — `AutoCaptureReceived`, `AutoCaptureConfirmed`, `AutoCaptureDismissed` not defined; state fields missing.

- [ ] **Step 3: Add new events to `quick_finance_event.dart`**

Open `lib/features/quick_finance/presentation/bloc/quick_finance_event.dart`. Add after the last existing event class:

```dart
final class AutoCaptureReceived extends QuickFinanceEvent {
  const AutoCaptureReceived(this.capture);
  final AutoCapturedTransaction capture;

  @override
  List<Object?> get props => [capture];
}

final class AutoCaptureConfirmed extends QuickFinanceEvent {
  const AutoCaptureConfirmed(
    this.capture, {
    this.editedNote,
    this.editedCategoryId,
  });
  final AutoCapturedTransaction capture;
  final String? editedNote;
  final String? editedCategoryId;

  @override
  List<Object?> get props => [capture, editedNote, editedCategoryId];
}

final class AutoCaptureDismissed extends QuickFinanceEvent {
  const AutoCaptureDismissed(this.capture);
  final AutoCapturedTransaction capture;

  @override
  List<Object?> get props => [capture];
}
```

Also add the import at the top if not present:
```dart
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
```

- [ ] **Step 4: Extend `QuickFinanceState`**

In `lib/features/quick_finance/presentation/bloc/quick_finance_state.dart`:

Add fields to the constructor:
```dart
const QuickFinanceState({
  // ... existing fields unchanged ...
  this.pendingCaptures = const [],
  this.needsNotificationAccess = false,
  this.needsShortcutsSetup = false,
});
```

Add field declarations after existing fields:
```dart
final List<AutoCapturedTransaction> pendingCaptures;
final bool needsNotificationAccess;
final bool needsShortcutsSetup;
```

Update `copyWith` — add parameters and return:
```dart
QuickFinanceState copyWith({
  // ... existing parameters unchanged ...
  List<AutoCapturedTransaction>? pendingCaptures,
  bool? needsNotificationAccess,
  bool? needsShortcutsSetup,
}) {
  return QuickFinanceState(
    // ... existing fields unchanged ...
    pendingCaptures: pendingCaptures ?? this.pendingCaptures,
    needsNotificationAccess: needsNotificationAccess ?? this.needsNotificationAccess,
    needsShortcutsSetup: needsShortcutsSetup ?? this.needsShortcutsSetup,
  );
}
```

Update `props`:
```dart
@override
List<Object?> get props => [
  // ... existing props unchanged ...
  pendingCaptures,
  needsNotificationAccess,
  needsShortcutsSetup,
];
```

Also add the import at the top:
```dart
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
fvm flutter test test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart
```
Expected: all 10 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/quick_finance/presentation/bloc/quick_finance_event.dart \
        lib/features/quick_finance/presentation/bloc/quick_finance_state.dart \
        test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart
git commit -m "feat(auto-capture): add pending queue events and state fields"
```

---

### Task 2: Wire new BLoC handlers

**Files:**
- Modify: `lib/features/quick_finance/presentation/bloc/quick_finance_bloc.dart`
- Test: `test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart` (extend)

**Interfaces:**
- Consumes: `AutoCaptureReceived`, `AutoCaptureConfirmed`, `AutoCaptureDismissed` from Task 1; `QuickFinanceState.pendingCaptures`, `.needsNotificationAccess`, `.needsShortcutsSetup` from Task 1.
- Consumes: `AutoCaptureService` (already injected via DI), `PaymentCaptureChannel` (via `AutoCaptureService`).
- Produces: `QuickFinanceBloc` handles all three new events and updates state correctly.

- [ ] **Step 1: Write failing BLoC handler tests**

Append to `test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
// ... add other imports matching existing test files in the project

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

// Add inside main():
group('QuickFinanceBloc auto-capture handlers', () {
  late QuickFinanceBloc bloc;
  late MockAddTransaction mockAdd;

  final capture = AutoCapturedTransaction(
    type: TransactionType.expense,
    amount: 50.0,
    note: 'McDonald\'s',
    occurredAt: DateTime(2026, 9, 25),
    sourceLabel: 'Google Wallet',
    category: 'comida',
  );

  setUp(() {
    mockAdd = MockAddTransaction();
    // ... set up other mocks with stubs for streams (return Stream.empty())
    bloc = QuickFinanceBloc(
      addTransaction: mockAdd,
      deleteTransaction: MockDeleteTransaction(),
      hydrateCurrentUserTransactions: MockHydrateCurrentUserTransactions(),
      watchBalance: MockWatchBalance(),
      watchTransactions: MockWatchTransactions(),
      updateTransaction: MockUpdateTransaction(),
      syncManager: MockSyncManager(),
      authDataSource: MockAuthDataSource(),
      goalRepository: MockGoalRepository(),
      debtRepository: MockDebtRepository(),
      deviceService: MockDeviceService(),
    );
  });

  tearDown(() => bloc.close());

  blocTest<QuickFinanceBloc, QuickFinanceState>(
    'AutoCaptureReceived appends to pendingCaptures',
    build: () => bloc,
    act: (b) => b.add(AutoCaptureReceived(capture)),
    expect: () => [
      isA<QuickFinanceState>()
          .having((s) => s.pendingCaptures, 'pendingCaptures', [capture]),
    ],
  );

  blocTest<QuickFinanceBloc, QuickFinanceState>(
    'AutoCaptureDismissed removes from pendingCaptures without saving',
    build: () => bloc,
    seed: () => QuickFinanceState(pendingCaptures: [capture]),
    act: (b) => b.add(AutoCaptureDismissed(capture)),
    expect: () => [
      isA<QuickFinanceState>()
          .having((s) => s.pendingCaptures, 'pendingCaptures', isEmpty),
    ],
    verify: (_) => verifyNever(() => mockAdd(any())),
  );

  blocTest<QuickFinanceBloc, QuickFinanceState>(
    'AutoCaptureConfirmed removes from pendingCaptures and calls addTransaction',
    build: () {
      when(() => mockAdd(any())).thenAnswer((_) async => const Right(null));
      return bloc;
    },
    seed: () => QuickFinanceState(pendingCaptures: [capture]),
    act: (b) => b.add(AutoCaptureConfirmed(capture)),
    expect: () => [
      isA<QuickFinanceState>()
          .having((s) => s.pendingCaptures, 'pendingCaptures', isEmpty),
    ],
    verify: (_) => verify(() => mockAdd(any())).called(1),
  );

  blocTest<QuickFinanceBloc, QuickFinanceState>(
    'AutoCaptureConfirmed with edits passes editedNote to AddTransactionRequested',
    build: () {
      when(() => mockAdd(any())).thenAnswer((_) async => const Right(null));
      return bloc;
    },
    seed: () => QuickFinanceState(pendingCaptures: [capture]),
    act: (b) => b.add(
      AutoCaptureConfirmed(capture, editedNote: 'KFC', editedCategoryId: 'comida'),
    ),
    verify: (b) {
      final call = verify(() => mockAdd(captureAny())).captured.first;
      // AddTransactionParams should carry editedNote
      expect((call as AddTransactionParams).note, 'KFC');
    },
  );

  blocTest<QuickFinanceBloc, QuickFinanceState>(
    'two AutoCaptureReceived events queue both captures',
    build: () => bloc,
    act: (b) {
      b.add(AutoCaptureReceived(capture));
      b.add(AutoCaptureReceived(capture));
    },
    expect: () => [
      isA<QuickFinanceState>()
          .having((s) => s.pendingCaptures.length, 'length', 1),
      isA<QuickFinanceState>()
          .having((s) => s.pendingCaptures.length, 'length', 2),
    ],
  );
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
fvm flutter test test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart
```
Expected: FAIL — handlers not yet registered.

- [ ] **Step 3: Register handlers in `QuickFinanceBloc` constructor**

In `lib/features/quick_finance/presentation/bloc/quick_finance_bloc.dart`, add inside the constructor body after existing `on<>` registrations:

```dart
on<AutoCaptureReceived>(_onAutoCaptureReceived);
on<AutoCaptureConfirmed>(_onAutoCaptureConfirmed);
on<AutoCaptureDismissed>(_onAutoCaptureDismissed);
```

- [ ] **Step 4: Add handler methods**

Add after the existing `_subscribeAutoCapture` method:

```dart
void _onAutoCaptureReceived(
  AutoCaptureReceived event,
  Emitter<QuickFinanceState> emit,
) {
  emit(state.copyWith(
    pendingCaptures: [...state.pendingCaptures, event.capture],
  ));
}

Future<void> _onAutoCaptureConfirmed(
  AutoCaptureConfirmed event,
  Emitter<QuickFinanceState> emit,
) async {
  final capture = event.capture;
  final note = event.editedNote ?? capture.note;
  final category = event.editedCategoryId ?? capture.category;

  // Remove from queue first so UI updates immediately
  emit(state.copyWith(
    pendingCaptures: state.pendingCaptures
        .where((c) => c != capture)
        .toList(),
  ));

  add(AddTransactionRequested(
    amount: capture.amount,
    type: capture.type,
    note: note,
    category: category,
    occurredAt: capture.occurredAt,
    autoSourceLabel: capture.sourceLabel,
  ));
}

void _onAutoCaptureDismissed(
  AutoCaptureDismissed event,
  Emitter<QuickFinanceState> emit,
) {
  emit(state.copyWith(
    pendingCaptures: state.pendingCaptures
        .where((c) => c != event.capture)
        .toList(),
  ));
}
```

- [ ] **Step 5: Update `_subscribeAutoCapture` to emit `AutoCaptureReceived` instead of `AddTransactionRequested`**

Find the current `_subscribeAutoCapture` method. It has a line like:
```dart
add(AddTransactionRequested(
  amount: t.amount,
  type: t.type,
  note: t.note,
  category: t.category,
  occurredAt: t.occurredAt,
  autoSourceLabel: t.sourceLabel,
));
```

Replace it with:
```dart
add(AutoCaptureReceived(t));
```

- [ ] **Step 6: Move `_notifyAutoCaptured` call from `_onAddTransactionRequested` into `_onAutoCaptureConfirmed`**

In `_onAddTransactionRequested`, find the block that calls `_notifyAutoCaptured` when `event.autoSourceLabel != null`. Remove that call.

In `_onAutoCaptureConfirmed`, after the `add(AddTransactionRequested(...))` call, add:
```dart
// Notification fires after the transaction is queued, not when it lands
// (the AddTransactionRequested handler persists it; notify here for immediacy)
await _notifyAutoCaptured(
  TransactionEntity(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    userId: '',
    type: capture.type,
    amount: capture.amount,
    note: note,
    categoryId: category,
    createdAt: capture.occurredAt,
    updatedAt: capture.occurredAt,
    syncStatus: SyncStatus.pending,
    version: 0,
    deviceId: '',
  ),
  capture.sourceLabel,
);
```

> Note: The notification is cosmetic — it uses the capture data, not the persisted entity. Pass `capture.sourceLabel` as the second argument.

- [ ] **Step 7: Add startup permission checks to `_subscribeAutoCapture`**

At the end of `_subscribeAutoCapture()`, add:

```dart
// Android: check notification listener access
if (Platform.isAndroid) {
  final granted = await sl<AutoCaptureService>().isAccessGranted();
  if (!granted) {
    final prefs = sl<SharedPreferences>();
    final suppressUntil = prefs.getInt('auto_capture_notification_suppress_until');
    final now = DateTime.now().millisecondsSinceEpoch;
    if (suppressUntil == null || now > suppressUntil) {
      emit(state.copyWith(needsNotificationAccess: true));
    }
  }
}

// iOS: check Shortcuts setup
if (Platform.isIOS) {
  final prefs = sl<SharedPreferences>();
  final done = prefs.getBool('auto_capture_shortcuts_setup_done') ?? false;
  if (!done) {
    emit(state.copyWith(needsShortcutsSetup: true));
  }
}
```

Add `import 'dart:io';` at the top of the file if not already present.
Add `import 'package:personal_finance/injection_container.dart';` if not already present (check existing imports — `sl` may already be available).

> Note: `_subscribeAutoCapture` may not be async. Change its signature to `Future<void> _subscribeAutoCapture() async` if needed, and await the call site in `_subscribeDataStreams`.

- [ ] **Step 8: Run tests**

```bash
fvm flutter test test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart
```
Expected: all tests PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/features/quick_finance/presentation/bloc/quick_finance_bloc.dart \
        test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart
git commit -m "feat(auto-capture): wire BLoC handlers for pending capture queue"
```

---

### Task 3: `AutoCaptureBottomSheet` widget

**Files:**
- Create: `lib/features/auto_capture/presentation/auto_capture_bottom_sheet.dart`
- Test: `test/features/auto_capture/presentation/auto_capture_bottom_sheet_test.dart`

**Interfaces:**
- Consumes: `AutoCapturedTransaction` from `auto_capture_service.dart`; `AutoCaptureConfirmed`, `AutoCaptureDismissed` events from Task 1.
- Produces: `AutoCaptureBottomSheet` — a `StatefulWidget` shown via `showModalBottomSheet`. Dispatches events to the nearest `QuickFinanceBloc`.

- [ ] **Step 1: Write failing widget test**

Create `test/features/auto_capture/presentation/auto_capture_bottom_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/auto_capture/presentation/auto_capture_bottom_sheet.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_event.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_state.dart';
import 'package:personal_finance/core/constants/enums.dart';

class MockQuickFinanceBloc extends MockBloc<QuickFinanceEvent, QuickFinanceState>
    implements QuickFinanceBloc {}

void main() {
  late MockQuickFinanceBloc mockBloc;

  final capture = AutoCapturedTransaction(
    type: TransactionType.expense,
    amount: 75.50,
    note: 'Uber',
    occurredAt: DateTime(2026, 9, 25),
    sourceLabel: 'Google Wallet',
    category: 'transporte',
  );

  setUp(() {
    mockBloc = MockQuickFinanceBloc();
    when(() => mockBloc.state).thenReturn(const QuickFinanceState());
  });

  Widget buildSheet() => MaterialApp(
    home: BlocProvider<QuickFinanceBloc>.value(
      value: mockBloc,
      child: Scaffold(
        body: AutoCaptureBottomSheet(capture: capture),
      ),
    ),
  );

  testWidgets('shows source label badge', (tester) async {
    await tester.pumpWidget(buildSheet());
    expect(find.text('Google Wallet'), findsOneWidget);
  });

  testWidgets('shows pre-filled amount', (tester) async {
    await tester.pumpWidget(buildSheet());
    expect(find.text('75.50'), findsOneWidget);
  });

  testWidgets('shows pre-filled note', (tester) async {
    await tester.pumpWidget(buildSheet());
    expect(find.text('Uber'), findsOneWidget);
  });

  testWidgets('confirm button dispatches AutoCaptureConfirmed', (tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    verify(() => mockBloc.add(AutoCaptureConfirmed(capture))).called(1);
  });

  testWidgets('dismiss button dispatches AutoCaptureDismissed', (tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.tap(find.text('Descartar'));
    await tester.pump();
    verify(() => mockBloc.add(AutoCaptureDismissed(capture))).called(1);
  });

  testWidgets('edited note is included in AutoCaptureConfirmed', (tester) async {
    await tester.pumpWidget(buildSheet());
    final noteField = find.widgetWithText(TextFormField, 'Uber');
    await tester.enterText(noteField, 'Uber Eats');
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    verify(() => mockBloc.add(
      AutoCaptureConfirmed(capture, editedNote: 'Uber Eats'),
    )).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
fvm flutter test test/features/auto_capture/presentation/auto_capture_bottom_sheet_test.dart
```
Expected: compilation error — `AutoCaptureBottomSheet` not defined.

- [ ] **Step 3: Create `auto_capture_bottom_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_event.dart';

class AutoCaptureBottomSheet extends StatefulWidget {
  const AutoCaptureBottomSheet({super.key, required this.capture});

  final AutoCapturedTransaction capture;

  @override
  State<AutoCaptureBottomSheet> createState() => _AutoCaptureBottomSheetState();
}

class _AutoCaptureBottomSheetState extends State<AutoCaptureBottomSheet> {
  late final TextEditingController _noteController;
  late final TextEditingController _amountController;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.capture.note);
    _amountController = TextEditingController(
      text: widget.capture.amount.toStringAsFixed(2),
    );
    _selectedCategory = widget.capture.category;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final editedNote = _noteController.text.trim();
    context.read<QuickFinanceBloc>().add(
      AutoCaptureConfirmed(
        widget.capture,
        editedNote: editedNote != widget.capture.note ? editedNote : null,
        editedCategoryId:
            _selectedCategory != widget.capture.category ? _selectedCategory : null,
      ),
    );
    Navigator.of(context).pop();
  }

  void _dismiss() {
    context.read<QuickFinanceBloc>().add(AutoCaptureDismissed(widget.capture));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source badge
          Chip(
            label: Text(
              widget.capture.sourceLabel,
              style: theme.textTheme.labelSmall,
            ),
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
          const SizedBox(height: 8),
          Text(
            'Pago detectado',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Amount field
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // Note field
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // Category (simple dropdown — extend with full category picker later)
          if (widget.capture.category != null)
            Text(
              'Categoría: ${_selectedCategory ?? widget.capture.category}',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _dismiss,
                  child: const Text('Descartar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirm,
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
fvm flutter test test/features/auto_capture/presentation/auto_capture_bottom_sheet_test.dart
```
Expected: all 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auto_capture/presentation/auto_capture_bottom_sheet.dart \
        test/features/auto_capture/presentation/auto_capture_bottom_sheet_test.dart
git commit -m "feat(auto-capture): add AutoCaptureBottomSheet confirmation widget"
```

---

### Task 4: `NotificationAccessBottomSheet` (Android)

**Files:**
- Create: `lib/features/auto_capture/presentation/notification_access_bottom_sheet.dart`
- Test: `test/features/auto_capture/presentation/notification_access_bottom_sheet_test.dart`

**Interfaces:**
- Consumes: `PaymentCaptureChannel.openAccessSettings()` (via `AutoCaptureService.openAccessSettings()`); `SharedPreferences` for suppression key `auto_capture_notification_suppress_until`.
- Produces: `NotificationAccessBottomSheet` — a stateless widget that takes `onEnable` and `onNotNow` callbacks.

- [ ] **Step 1: Write failing widget test**

Create `test/features/auto_capture/presentation/notification_access_bottom_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/auto_capture/presentation/notification_access_bottom_sheet.dart';

void main() {
  testWidgets('shows explanation text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationAccessBottomSheet(
          onEnable: () {},
          onNotNow: () {},
        ),
      ),
    ));
    expect(find.textContaining('notificaciones'), findsOneWidget);
  });

  testWidgets('Enable button calls onEnable', (tester) async {
    var called = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationAccessBottomSheet(
          onEnable: () => called = true,
          onNotNow: () {},
        ),
      ),
    ));
    await tester.tap(find.text('Activar'));
    expect(called, isTrue);
  });

  testWidgets('Not now button calls onNotNow', (tester) async {
    var called = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationAccessBottomSheet(
          onEnable: () {},
          onNotNow: () => called = true,
        ),
      ),
    ));
    await tester.tap(find.text('Ahora no'));
    expect(called, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
fvm flutter test test/features/auto_capture/presentation/notification_access_bottom_sheet_test.dart
```
Expected: compilation error.

- [ ] **Step 3: Create `notification_access_bottom_sheet.dart`**

```dart
import 'package:flutter/material.dart';

class NotificationAccessBottomSheet extends StatelessWidget {
  const NotificationAccessBottomSheet({
    super.key,
    required this.onEnable,
    required this.onNotNow,
  });

  final VoidCallback onEnable;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_active_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            'Acceso a notificaciones',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para detectar pagos automáticamente, la app necesita '
            'permiso para leer notificaciones de apps de pago y banco. '
            'Solo se procesan notificaciones de montos y comercios.',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onNotNow,
                  child: const Text('Ahora no'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onEnable,
                  child: const Text('Activar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
fvm flutter test test/features/auto_capture/presentation/notification_access_bottom_sheet_test.dart
```
Expected: all 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auto_capture/presentation/notification_access_bottom_sheet.dart \
        test/features/auto_capture/presentation/notification_access_bottom_sheet_test.dart
git commit -m "feat(auto-capture): add NotificationAccessBottomSheet widget"
```

---

### Task 5: `ShortcutsSetupBottomSheet` (iOS)

**Files:**
- Create: `lib/features/auto_capture/presentation/shortcuts_setup_bottom_sheet.dart`
- Test: `test/features/auto_capture/presentation/shortcuts_setup_bottom_sheet_test.dart`

**Interfaces:**
- Produces: `ShortcutsSetupBottomSheet` — takes `onGotIt` and `onRemindLater` callbacks; shows step-by-step Shortcuts instructions and the URL scheme to copy.

- [ ] **Step 1: Write failing widget test**

Create `test/features/auto_capture/presentation/shortcuts_setup_bottom_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/auto_capture/presentation/shortcuts_setup_bottom_sheet.dart';

void main() {
  testWidgets('shows Shortcuts explanation text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShortcutsSetupBottomSheet(
          onGotIt: () {},
          onRemindLater: () {},
        ),
      ),
    ));
    expect(find.textContaining('Shortcuts'), findsOneWidget);
  });

  testWidgets('shows URL scheme to copy', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShortcutsSetupBottomSheet(
          onGotIt: () {},
          onRemindLater: () {},
        ),
      ),
    ));
    expect(find.textContaining('personalfinance://pago'), findsOneWidget);
  });

  testWidgets('Got it button calls onGotIt', (tester) async {
    var called = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShortcutsSetupBottomSheet(
          onGotIt: () => called = true,
          onRemindLater: () {},
        ),
      ),
    ));
    await tester.tap(find.text('Entendido'));
    expect(called, isTrue);
  });

  testWidgets('Remind later button calls onRemindLater', (tester) async {
    var called = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShortcutsSetupBottomSheet(
          onGotIt: () {},
          onRemindLater: () => called = true,
        ),
      ),
    ));
    await tester.tap(find.text('Recordarme después'));
    expect(called, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
fvm flutter test test/features/auto_capture/presentation/shortcuts_setup_bottom_sheet_test.dart
```
Expected: compilation error.

- [ ] **Step 3: Create `shortcuts_setup_bottom_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShortcutsSetupBottomSheet extends StatelessWidget {
  const ShortcutsSetupBottomSheet({
    super.key,
    required this.onGotIt,
    required this.onRemindLater,
  });

  final VoidCallback onGotIt;
  final VoidCallback onRemindLater;

  static const _urlScheme =
      'personalfinance://pago?monto=[Amount]&comercio=[Merchant Name]&tipo=gasto';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shortcut_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            'Configurar Apple Pay con Shortcuts',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los pagos con Apple Pay se detectan mediante una '
            'automatización gratuita en la app Shortcuts de iOS.',
          ),
          const SizedBox(height: 16),
          _Step(number: 1, text: 'Abre la app Shortcuts en tu iPhone.'),
          _Step(number: 2, text: 'Toca "+" → "Nueva automatización".'),
          _Step(number: 3, text: 'Selecciona "Apple Pay" como disparador.'),
          _Step(number: 4, text: 'Agrega la acción "Abrir URL".'),
          _Step(number: 5, text: 'Pega la siguiente URL:'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: _urlScheme));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL copiada al portapapeles')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _urlScheme,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const Icon(Icons.copy, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRemindLater,
                  child: const Text('Recordarme después'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onGotIt,
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text('$number', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
fvm flutter test test/features/auto_capture/presentation/shortcuts_setup_bottom_sheet_test.dart
```
Expected: all 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auto_capture/presentation/shortcuts_setup_bottom_sheet.dart \
        test/features/auto_capture/presentation/shortcuts_setup_bottom_sheet_test.dart
git commit -m "feat(auto-capture): add ShortcutsSetupBottomSheet for iOS guide"
```

---

### Task 6: Wire bottom sheets into `QuickFinanceHomePage`

**Files:**
- Modify: `lib/features/quick_finance/presentation/pages/quick_finance_home_page.dart`

**Interfaces:**
- Consumes: `AutoCaptureBottomSheet`, `NotificationAccessBottomSheet`, `ShortcutsSetupBottomSheet` from Tasks 3-5.
- Consumes: `QuickFinanceState.pendingCaptures`, `.needsNotificationAccess`, `.needsShortcutsSetup` from Task 1.
- Consumes: `AutoCaptureConfirmed`, `AutoCaptureDismissed` events dispatched inside the sheets (no direct dispatch from the page).
- Consumes: `AutoCaptureService.openAccessSettings()` and `SharedPreferences` for suppress/done flags.

- [ ] **Step 1: Add imports to `quick_finance_home_page.dart`**

```dart
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/auto_capture/presentation/auto_capture_bottom_sheet.dart';
import 'package:personal_finance/features/auto_capture/presentation/notification_access_bottom_sheet.dart';
import 'package:personal_finance/features/auto_capture/presentation/shortcuts_setup_bottom_sheet.dart';
import 'package:personal_finance/injection_container.dart';
```

> Check existing imports — `sl`, `SharedPreferences`, `AutoCaptureService` may already be imported. Add only what's missing.

- [ ] **Step 2: Replace or extend the `BlocListener` in the page's `build` method**

The page currently uses a `BlocListener` or `BlocConsumer`. Locate the `listenWhen` / `listener` block. Extend `listener` with three new conditions:

```dart
// Inside the existing BlocListener's listener callback, add:

// 1. Auto-capture confirmation
if (state.pendingCaptures.isNotEmpty && !_sheetOpen) {
  _sheetOpen = true;
  final capture = state.pendingCaptures.first;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<QuickFinanceBloc>(),
      child: AutoCaptureBottomSheet(capture: capture),
    ),
  ).whenComplete(() => _sheetOpen = false);
}

// 2. Android notification access
if (state.needsNotificationAccess && Platform.isAndroid && !_sheetOpen) {
  _sheetOpen = true;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => NotificationAccessBottomSheet(
      onEnable: () async {
        Navigator.of(context).pop();
        await sl<AutoCaptureService>().openAccessSettings();
        _sheetOpen = false;
      },
      onNotNow: () async {
        Navigator.of(context).pop();
        final prefs = await SharedPreferences.getInstance();
        final suppress = DateTime.now()
            .add(const Duration(days: 7))
            .millisecondsSinceEpoch;
        await prefs.setInt('auto_capture_notification_suppress_until', suppress);
        // Clear the flag in state
        if (mounted) {
          context.read<QuickFinanceBloc>().emit(
            context.read<QuickFinanceBloc>().state.copyWith(
              needsNotificationAccess: false,
            ),
          );
        }
        _sheetOpen = false;
      },
    ),
  ).whenComplete(() => _sheetOpen = false);
}

// 3. iOS Shortcuts setup
if (state.needsShortcutsSetup && Platform.isIOS && !_sheetOpen) {
  _sheetOpen = true;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ShortcutsSetupBottomSheet(
      onGotIt: () async {
        Navigator.of(context).pop();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auto_capture_shortcuts_setup_done', true);
        if (mounted) {
          context.read<QuickFinanceBloc>().emit(
            context.read<QuickFinanceBloc>().state.copyWith(
              needsShortcutsSetup: false,
            ),
          );
        }
        _sheetOpen = false;
      },
      onRemindLater: () {
        Navigator.of(context).pop();
        if (mounted) {
          context.read<QuickFinanceBloc>().emit(
            context.read<QuickFinanceBloc>().state.copyWith(
              needsShortcutsSetup: false,
            ),
          );
        }
        _sheetOpen = false;
      },
    ),
  ).whenComplete(() => _sheetOpen = false);
}
```

- [ ] **Step 3: Add `_sheetOpen` guard field**

In `_QuickFinanceHomePageState`, add:
```dart
bool _sheetOpen = false;
```

> This prevents stacking multiple bottom sheets when several state changes arrive together.

- [ ] **Step 4: Update `listenWhen` to include new state fields**

If the page uses `listenWhen`, add the new fields:

```dart
listenWhen: (prev, next) =>
    prev.status != next.status ||
    prev.pendingCaptures != next.pendingCaptures ||
    prev.needsNotificationAccess != next.needsNotificationAccess ||
    prev.needsShortcutsSetup != next.needsShortcutsSetup ||
    // ... existing conditions ...
```

- [ ] **Step 5: Verify app compiles**

```bash
fvm flutter build apk --debug 2>&1 | tail -20
```
Expected: build succeeds with no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/quick_finance/presentation/pages/quick_finance_home_page.dart
git commit -m "feat(auto-capture): wire confirmation and onboarding bottom sheets in home page"
```

---

### Task 7: Full test suite run and cleanup

**Files:**
- No new files.

- [ ] **Step 1: Run all auto-capture tests**

```bash
fvm flutter test test/features/auto_capture/ test/features/quick_finance/bloc/quick_finance_bloc_auto_capture_test.dart --reporter=expanded
```
Expected: all tests PASS.

- [ ] **Step 2: Run full test suite**

```bash
fvm flutter test
```
Expected: no regressions in existing tests.

- [ ] **Step 3: Final commit if any fixes were needed**

```bash
git add -p  # stage only test/fix changes
git commit -m "fix(auto-capture): address test suite issues"
```
