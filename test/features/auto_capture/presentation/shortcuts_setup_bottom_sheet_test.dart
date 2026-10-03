import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/auto_capture/presentation/shortcuts_setup_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSheet({required VoidCallback onGotIt, required VoidCallback onRemindLater}) =>
      MaterialApp(
        home: Scaffold(
          body: ShortcutsSetupBottomSheet(
            onGotIt: onGotIt,
            onRemindLater: onRemindLater,
          ),
        ),
      );

  testWidgets('shows Shortcuts explanation text', (tester) async {
    await tester.pumpWidget(buildSheet(onGotIt: () {}, onRemindLater: () {}));
    expect(find.textContaining('Shortcuts'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows URL scheme to copy', (tester) async {
    await tester.pumpWidget(buildSheet(onGotIt: () {}, onRemindLater: () {}));
    expect(find.textContaining('personalfinance://pago'), findsOneWidget);
  });

  testWidgets('Entendido button calls onGotIt', (tester) async {
    var called = false;
    await tester.pumpWidget(buildSheet(onGotIt: () => called = true, onRemindLater: () {}));
    await tester.tap(find.text('Entendido'));
    expect(called, isTrue);
  });

  testWidgets('Recordarme después button calls onRemindLater', (tester) async {
    var called = false;
    await tester.pumpWidget(buildSheet(onGotIt: () {}, onRemindLater: () => called = true));
    await tester.tap(find.text('Recordarme después'));
    expect(called, isTrue);
  });

  testWidgets('Entendido does not call onRemindLater', (tester) async {
    var laterCalled = false;
    await tester.pumpWidget(
      buildSheet(onGotIt: () {}, onRemindLater: () => laterCalled = true),
    );
    await tester.tap(find.text('Entendido'));
    expect(laterCalled, isFalse);
  });
}
