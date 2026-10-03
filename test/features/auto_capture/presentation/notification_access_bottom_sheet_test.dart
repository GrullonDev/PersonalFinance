import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/auto_capture/presentation/notification_access_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSheet({required VoidCallback onEnable, required VoidCallback onNotNow}) =>
      MaterialApp(
        home: Scaffold(
          body: NotificationAccessBottomSheet(
            onEnable: onEnable,
            onNotNow: onNotNow,
          ),
        ),
      );

  testWidgets('shows explanation mentioning notifications', (tester) async {
    await tester.pumpWidget(buildSheet(onEnable: () {}, onNotNow: () {}));
    expect(find.textContaining('notificaciones'), findsAtLeastNWidgets(1));
  });

  testWidgets('Activar button calls onEnable', (tester) async {
    var called = false;
    await tester.pumpWidget(buildSheet(onEnable: () => called = true, onNotNow: () {}));
    await tester.tap(find.text('Activar'));
    expect(called, isTrue);
  });

  testWidgets('Ahora no button calls onNotNow', (tester) async {
    var called = false;
    await tester.pumpWidget(buildSheet(onEnable: () {}, onNotNow: () => called = true));
    await tester.tap(find.text('Ahora no'));
    expect(called, isTrue);
  });

  testWidgets('Activar does not call onNotNow', (tester) async {
    var notNowCalled = false;
    await tester.pumpWidget(
      buildSheet(onEnable: () {}, onNotNow: () => notNowCalled = true),
    );
    await tester.tap(find.text('Activar'));
    expect(notNowCalled, isFalse);
  });
}
