import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/auto_capture/presentation/shortcuts_setup_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSheet({
    required VoidCallback onOpenShortcuts,
    required VoidCallback onClose,
  }) => MaterialApp(
    home: Scaffold(
      body: ShortcutsSetupBottomSheet(
        onOpenShortcuts: onOpenShortcuts,
        onClose: onClose,
      ),
    ),
  );

  testWidgets('shows Shortcuts explanation text', (tester) async {
    await tester.pumpWidget(buildSheet(onOpenShortcuts: () {}, onClose: () {}));
    expect(find.textContaining('Shortcuts'), findsAtLeastNWidgets(1));
  });

  testWidgets('explica la acción "Registrar pago" con variables', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet(onOpenShortcuts: () {}, onClose: () {}));
    expect(find.textContaining('Registrar pago'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Importe'), findsOneWidget);
    expect(find.textContaining('personalfinance://'), findsNothing);
    expect(
      find.textContaining('Registrar mensaje bancario'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('Abrir Atajos button calls onOpenShortcuts', (tester) async {
    var called = false;
    await tester.pumpWidget(
      buildSheet(onOpenShortcuts: () => called = true, onClose: () {}),
    );
    await tester.ensureVisible(find.text('Abrir Atajos'));
    await tester.tap(find.text('Abrir Atajos'));
    expect(called, isTrue);
  });

  testWidgets('Cerrar button calls onClose', (tester) async {
    var called = false;
    await tester.pumpWidget(
      buildSheet(onOpenShortcuts: () {}, onClose: () => called = true),
    );
    await tester.ensureVisible(find.text('Cerrar'));
    await tester.tap(find.text('Cerrar'));
    expect(called, isTrue);
  });

  testWidgets('Abrir Atajos does not call onClose', (tester) async {
    var laterCalled = false;
    await tester.pumpWidget(
      buildSheet(onOpenShortcuts: () {}, onClose: () => laterCalled = true),
    );
    await tester.ensureVisible(find.text('Abrir Atajos'));
    await tester.tap(find.text('Abrir Atajos'));
    expect(laterCalled, isFalse);
  });
}
