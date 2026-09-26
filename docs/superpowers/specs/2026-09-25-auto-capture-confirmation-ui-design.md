# Auto-Capture Confirmation UI Design

**Date:** 2026-09-25
**Feature:** Payment auto-capture confirmation bottom sheets (iOS & Android)

---

## Overview

The app already detects payments passively:
- **Android** — `PaymentNotificationListener` monitors Google Pay, Google Wallet, Samsung Wallet, and bank SMS notifications via `NotificationListenerService`.
- **iOS** — A user-configured Shortcuts automation fires a URL callback (`personalfinance://pago?...`) when Apple Pay is used.

The `AutoCaptureService` processes raw captures and emits `AutoCapturedTransaction` objects. Currently the `QuickFinanceBloc` converts these directly into saved transactions (silently). This design adds a **user confirmation step** via a bottom sheet before any auto-captured transaction is persisted.

---

## Goals

1. Auto-captured payments pause in a pending queue and show a bottom sheet for the user to review, edit, and confirm or dismiss.
2. On Android, if notification listener access is not granted, prompt the user to enable it once (suppress for 7 days on "Not now").
3. On iOS, if the Shortcuts automation has never been configured, show a one-time setup guide.

---

## Architecture — BLoC Changes

### New Events (`quick_finance_event.dart`)

```
AutoCaptureReceived(AutoCapturedTransaction capture)
AutoCaptureConfirmed(AutoCapturedTransaction capture, {String? editedNote, String? editedCategoryId})
AutoCaptureDismissed(AutoCapturedTransaction capture)
```

### New State Fields (`quick_finance_state.dart`)

```
List<AutoCapturedTransaction> pendingCaptures   // default const []
bool needsNotificationAccess                    // default false (Android only)
bool needsShortcutsSetup                        // default false (iOS only)
```

### BLoC Behaviour (`quick_finance_bloc.dart`)

- `_subscribeAutoCapture()` emits `AutoCaptureReceived` instead of directly firing `AddTransactionRequested`.
- `_onAutoCaptureReceived` appends to `pendingCaptures`.
- `_onAutoCaptureConfirmed` fires `AddTransactionRequested` (with `autoSourceLabel` set), removes the capture from `pendingCaptures`, and fires the local notification (moved from the current silent path).
- `_onAutoCaptureDismissed` removes the capture from `pendingCaptures` only.
- On startup (`_subscribeAutoCapture`), check `channel.isAccessGranted()`:
  - Android false → emit `needsNotificationAccess: true` (unless suppressed in SharedPreferences for 7 days).
  - iOS, Shortcuts flag not set → emit `needsShortcutsSetup: true`.

---

## UI — Bottom Sheets

### `AutoCaptureBottomSheet` (new file)

Shown by `QuickFinanceHomePage`'s `BlocListener` when `pendingCaptures` is non-empty. Shows one sheet at a time; when confirmed or dismissed, the next pending capture triggers automatically.

**Fields:**
- Source label badge (e.g. "Google Wallet", "Apple Pay Shortcut")
- Amount field (pre-filled, editable)
- Note field (pre-filled with merchant name, editable)
- Category picker (pre-selected from `MerchantCategorizer` result, changeable)
- **Confirm** button → dispatches `AutoCaptureConfirmed`
- **Dismiss** button → dispatches `AutoCaptureDismissed`

### `NotificationAccessBottomSheet` (new file, Android only)

Shown when `needsNotificationAccess == true`.

- Brief explanation of why notification access is needed
- **Enable** button → calls `channel.openAccessSettings()`
- **Not now** button → writes suppression timestamp to SharedPreferences, clears `needsNotificationAccess`

### `ShortcutsSetupBottomSheet` (new file, iOS only)

Shown when `needsShortcutsSetup == true`.

- Explanation: "Apple Pay transactions are detected via a free Shortcuts automation"
- Step-by-step instructions: open Shortcuts → New Automation → Apple Pay → Run Shortcut → enter URL
- URL to copy: `personalfinance://pago?monto=[Amount]&comercio=[Merchant Name]&tipo=gasto`
- **Got it** button → writes setup flag to SharedPreferences, clears `needsShortcutsSetup`
- **Remind me later** button → clears flag without persisting (shows again next session)

---

## Files Touched

| File | Change |
|------|--------|
| `lib/features/quick_finance/presentation/bloc/quick_finance_event.dart` | Add `AutoCaptureReceived`, `AutoCaptureConfirmed`, `AutoCaptureDismissed` |
| `lib/features/quick_finance/presentation/bloc/quick_finance_state.dart` | Add `pendingCaptures`, `needsNotificationAccess`, `needsShortcutsSetup` |
| `lib/features/quick_finance/presentation/bloc/quick_finance_bloc.dart` | Wire new event handlers, startup permission checks, move notification to confirm |
| `lib/features/quick_finance/presentation/pages/quick_finance_home_page.dart` | `BlocListener` drives all three bottom sheets |
| `lib/features/auto_capture/presentation/auto_capture_bottom_sheet.dart` | New — confirmation UI |
| `lib/features/auto_capture/presentation/notification_access_bottom_sheet.dart` | New — Android permission prompt |
| `lib/features/auto_capture/presentation/shortcuts_setup_bottom_sheet.dart` | New — iOS Shortcuts guide |

---

## Out of Scope

- Changing how `AutoCaptureService`, `PaymentCaptureChannel`, or the native Kotlin/Swift code works — those are already correct.
- Adding auto-capture to any page other than `QuickFinanceHomePage`.
- Income auto-capture UI (uses the same bottom sheet; no special case needed).
