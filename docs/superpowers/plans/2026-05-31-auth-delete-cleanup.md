# Auth Double-Load Fix, Hard Delete, & Dead Code Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the auth loading flicker on login, make debt (and verify goal) deletion permanent via hard delete, and remove dead code files.

**Architecture:** Three independent fixes on the `refactor/auth-delete-cleanup` branch. Auth fix is a refactor of `AuthProvider` — extract a private `_fetchUserData()` that does the I/O without touching `_isLoading`, so callers that already manage loading state don't get a premature spinner-stop. Debt delete fix replaces `softDelete` with a direct Firestore `.delete()` call. Dead code removal deletes three unused files/directories.

**Tech Stack:** Flutter, Dart, Firebase Auth, Cloud Firestore, `ChangeNotifier`, `dartz` Either, `mocktail`

---

## File Map

| Action | File | Change |
|--------|------|--------|
| Modify | `lib/features/auth/presentation/providers/auth_provider.dart` | Extract `_fetchUserData()`, update `loadCurrentUser()` to delegate, update `signInWithGoogle()` / `signInWithApple()` to call `_fetchUserData()` directly |
| Modify | `lib/features/debts/data/datasources/debt_remote_data_source.dart` | Change `deleteDebt` from `softDelete(id)` to `_userCollection.doc(id).delete()` |
| Delete | `lib/features/budget/` | Entire directory (unused) |
| Delete | `lib/features/expenses/pages/expenses_page.dart` | Unused page |
| Delete | `lib/features/services/presentation/pages/service_consultation_page.dart` | Unused page |

---

## Task 1: Fix Auth Double-Loading Flicker

**Root cause:** `loadCurrentUser()` manages its own `_isLoading` state — it calls `_isLoading = true; notifyListeners()` at the top and `_isLoading = false; notifyListeners()` in the `finally` block. When called from inside `signInWithGoogle()` (which is already in a loading state), `loadCurrentUser`'s `finally` prematurely fires `_isLoading = false`, stopping the spinner before navigation. Then `signInWithGoogle` calls `_setLoading(false)` again on a spinner that's already off — causing a visible flicker.

**Fix:** Extract `_fetchUserData()` — does the I/O work without touching `_isLoading`. `loadCurrentUser()` wraps `_fetchUserData()` with its own loading guard (public API unchanged). `signInWithGoogle()` and `signInWithApple()` call `_fetchUserData()` directly instead of `loadCurrentUser()`.

**Files:**
- Modify: `lib/features/auth/presentation/providers/auth_provider.dart`

- [ ] **Step 1: Add `_fetchUserData()` private method**

Open `lib/features/auth/presentation/providers/auth_provider.dart`. After the `_handleSuccessfulLogin` method (around line 149), add the following private method. It is a direct extraction of the body of `loadCurrentUser()` with no changes to `_isLoading`:

```dart
/// Fetches the current user from the repository and updates [_currentUser].
/// Does NOT touch [_isLoading] — callers manage loading state themselves.
Future<Either<AuthFailure, CurrentUserResponse>> _fetchUserData() async {
  _errorMessage = null;

  try {
    final bool restored = await syncSessionFromFirebase();
    if (!restored) {
      _errorMessage =
          'Tu sesión no está disponible. Inicia sesión nuevamente.';
      notifyListeners();
      return const Left(
        AuthFailure(
          message: 'Tu sesión no está disponible. Inicia sesión nuevamente.',
        ),
      );
    }

    final Either<AuthFailure, CurrentUserResponse> result =
        await authRepository.getCurrentUser();
    return result.fold(
      (AuthFailure failure) {
        _errorMessage = _localizeAuthMessage(failure.message);
        if (failure.message.toLowerCase().contains('expired') ||
            failure.message.toLowerCase().contains('invalid')) {
          _clearAuthData();
        }
        notifyListeners();
        return Left(AuthFailure(message: _errorMessage!));
      },
      (CurrentUserResponse user) {
        _currentUser = user;
        _saveAuthData();
        notifyListeners();
        return Right(user);
      },
    );
  } catch (e) {
    _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
    await _clearAuthData();
    notifyListeners();
    return const Left(
      AuthFailure(message: 'Ocurrió un error inesperado. Intenta de nuevo.'),
    );
  }
}
```

- [ ] **Step 2: Update `loadCurrentUser()` to delegate to `_fetchUserData()`**

Replace the body of `loadCurrentUser()` (lines ~409-457) with a thin wrapper that manages loading state and delegates:

```dart
Future<Either<AuthFailure, CurrentUserResponse>> loadCurrentUser() async {
  _isLoading = true;
  notifyListeners();
  try {
    return await _fetchUserData();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

- [ ] **Step 3: Update `signInWithGoogle()` to call `_fetchUserData()` instead of `loadCurrentUser()`**

In `signInWithGoogle()` (around line 82), replace `await loadCurrentUser();` with:

```dart
await _fetchUserData();
```

The surrounding code in `signInWithGoogle()` already owns `_isLoading` (it called `_setLoading(true)` at the start and calls `_setLoading(false)` at the end), so removing the inner `loadCurrentUser()` call means no premature loading stop.

- [ ] **Step 4: Update `signInWithApple()` the same way**

In `signInWithApple()` (around line 115), replace `await loadCurrentUser();` with:

```dart
await _fetchUserData();
```

- [ ] **Step 5: Verify no other callers of `loadCurrentUser()` break**

Search for all calls to `loadCurrentUser()`:

```bash
grep -rn "loadCurrentUser" lib/
```

Expected callers:
- `auth_provider.dart` itself: `_init()` calls `loadCurrentUser()` — this is fine, it already doesn't manage `_isLoading` before calling it, so the wrapper's loading guard is correct here.
- `auth_provider.dart`: `onAppResumed()` calls `loadCurrentUser()` — also fine, same reason.

If any other caller is found outside `auth_provider.dart`, evaluate whether it should call `_fetchUserData()` or `loadCurrentUser()`. If it's already inside a loading-guarded block, switch it to `_fetchUserData()`.

- [ ] **Step 6: Run the analyzer**

```bash
flutter analyze lib/features/auth/presentation/providers/auth_provider.dart
```

Expected: No errors, no warnings.

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/presentation/providers/auth_provider.dart
git commit -m "fix: eliminate auth loading flicker by extracting _fetchUserData()"
```

---

## Task 2: Fix Debt Hard Delete

**Root cause:** `deleteDebt` calls `softDelete(id)` which sets `deletedAt` in Firestore rather than deleting the document. While `getDebts()` uses `getAll()` which filters `where('deletedAt', isNull: true)`, a bug or race in the Firestore index can cause the soft-deleted document to reappear. Hard delete removes the document entirely — it can never come back on refresh.

**Files:**
- Modify: `lib/features/debts/data/datasources/debt_remote_data_source.dart`

- [ ] **Step 1: Confirm `_userCollection` is accessible**

`DebtRemoteDataSourceImpl` extends `BaseFirestoreService<DebtModel>`. `BaseFirestoreService` exposes `_userCollection` as a private getter. Since `DebtRemoteDataSourceImpl` can't access `_userCollection` directly (it's private to `BaseFirestoreService`), we need to either:
- Add a `hardDelete(String id)` method to `BaseFirestoreService`, or
- Inline the Firestore call using `FirebaseFirestore.instance` directly.

The cleaner approach is adding `hardDelete` to `BaseFirestoreService` — it stays consistent with the existing pattern and can be reused.

Open `lib/core/data/datasources/base_firestore_service.dart`. After the `softDelete` method (line 48-53), add:

```dart
Future<void> hardDelete(String id) async {
  await _userCollection.doc(id).delete();
}
```

- [ ] **Step 2: Update `deleteDebt` to call `hardDelete`**

In `lib/features/debts/data/datasources/debt_remote_data_source.dart`, replace the body of `deleteDebt`:

```dart
@override
Future<void> deleteDebt(String id) async {
  try {
    await hardDelete(id);
  } catch (e) {
    throw ApiException(message: e.toString(), statusCode: 500);
  }
}
```

- [ ] **Step 3: Run the analyzer**

```bash
flutter analyze lib/core/data/datasources/base_firestore_service.dart lib/features/debts/data/datasources/debt_remote_data_source.dart
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/data/datasources/base_firestore_service.dart lib/features/debts/data/datasources/debt_remote_data_source.dart
git commit -m "fix: use hard delete for debts so items don't reappear after refresh"
```

---

## Task 3: Verify Goal Delete (No Change Needed / Guard Null ID)

**Context:** `goal_remote_data_source.dart` already calls `_goalsCollection.doc(id).delete()` — hard delete. The symptom (item disappears and reappears) may also affect goals if the goal's `id` is null at delete time.

**Root cause of null id:** `GoalModel.id` is `String?`. If a goal was created but the returned model lost its Firestore document ID before being stored in state, `goal.id` would be null and `_goalsCollection.doc(null)` would either throw (not caught) or silently no-op. The BLoC would then optimistically remove the item from the list, but the document still exists in Firestore — it reappears on refresh.

**Files:**
- Read: `lib/features/goals/data/datasources/goal_remote_data_source.dart`
- Possibly modify: `lib/features/goals/presentation/bloc/goals_bloc.dart`

- [ ] **Step 1: Read `goal_remote_data_source.dart` to confirm current delete implementation**

```bash
cat lib/features/goals/data/datasources/goal_remote_data_source.dart
```

Confirm `deleteGoal` calls `.delete()` on the collection reference (not `softDelete`). If it already does, no change needed in the data source.

- [ ] **Step 2: Add a null-id guard in the BLoC delete handler**

Open `lib/features/goals/presentation/bloc/goals_bloc.dart`. Find the `_onDelete` handler (or equivalent). Add a guard before dispatching the delete:

```dart
Future<void> _onDelete(DeleteGoal event, Emitter<GoalsState> emit) async {
  if (event.id == null || event.id!.isEmpty) {
    // Goal has no Firestore ID — it was never persisted; just remove from UI
    emit(state.copyWith(
      goals: state.goals.where((g) => g.id != event.id).toList(),
    ));
    return;
  }
  // ... existing delete logic ...
}
```

Note: Adapt the guard to match the actual handler signature and state shape in the file. Read the file first.

- [ ] **Step 3: Run the analyzer**

```bash
flutter analyze lib/features/goals/
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/goals/presentation/bloc/goals_bloc.dart
git commit -m "fix: guard against null goal id in delete handler to prevent phantom reappearance"
```

If no change was needed (the handler already has a guard or the id is always non-null from Firestore), skip the commit and note it.

---

## Task 4: Remove Dead Code Files

**Files to delete:**
- `lib/features/budget/` — entire directory (contains only `budget_model.dart`, imported nowhere)
- `lib/features/expenses/pages/expenses_page.dart` — never routed
- `lib/features/services/presentation/pages/service_consultation_page.dart` — never routed

- [ ] **Step 1: Confirm nothing imports these files**

```bash
grep -rn "features/budget" lib/
grep -rn "expenses_page" lib/
grep -rn "service_consultation_page" lib/
```

Expected: No results (or only results inside the files themselves). If any live code imports them, do NOT delete — report as BLOCKED.

- [ ] **Step 2: Delete the files**

```bash
rm -rf lib/features/budget/
rm lib/features/expenses/pages/expenses_page.dart
rm lib/features/services/presentation/pages/service_consultation_page.dart
```

- [ ] **Step 3: Check if parent directories are now empty (clean them up)**

```bash
ls lib/features/expenses/pages/
ls lib/features/services/presentation/pages/
```

If `lib/features/expenses/pages/` is now empty (or the `expenses` feature has no other files), remove the empty directory. Same for `services/presentation/pages/`. Only delete directories that are fully empty.

```bash
# Only run these if the directories are empty:
rmdir lib/features/expenses/pages/   # if empty
rmdir lib/features/services/presentation/pages/  # if empty
```

- [ ] **Step 4: Run the analyzer across the whole project**

```bash
flutter analyze
```

Expected: No errors introduced by the deletions.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove unused budget, expenses page, and service consultation page files"
```

---

## Self-Review

**Spec coverage:**
- Auth double-load flicker → Task 1 ✓ (extract `_fetchUserData`, update callers)
- Debt hard delete → Task 2 ✓ (add `hardDelete` to base, call from `deleteDebt`)
- Goal delete guard → Task 3 ✓ (verify and add null-id guard)
- Dead code removal → Task 4 ✓ (confirm no imports, delete, clean dirs)

**Placeholder scan:** None found. All steps have concrete code or concrete commands.

**Type consistency:** `_fetchUserData()` returns `Future<Either<AuthFailure, CurrentUserResponse>>` — same signature as `loadCurrentUser()`. `hardDelete(String id)` matches the `String id` parameter in `deleteDebt`.

**Edge cases covered:**
- `_init()` and `onAppResumed()` call `loadCurrentUser()` (the wrapper), not `_fetchUserData()` — loading state managed correctly.
- `hardDelete` in base class uses `_userCollection` which throws if user is null — same behavior as `softDelete`.
- Task 3 instructs to read the goals BLoC before modifying — implementation adapts to actual code.
