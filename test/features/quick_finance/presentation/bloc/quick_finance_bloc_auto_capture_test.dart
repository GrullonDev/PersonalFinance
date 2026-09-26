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
      note: "McDonald's",
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
