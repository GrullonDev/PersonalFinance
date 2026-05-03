import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState renderiza título, mensaje y acción', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            title: 'Sin datos',
            message: 'Agrega tu primera transacción para comenzar.',
            action: FilledButton(onPressed: () {}, child: const Text('Crear')),
          ),
        ),
      ),
    );

    expect(find.text('Sin datos'), findsOneWidget);
    expect(
      find.text('Agrega tu primera transacción para comenzar.'),
      findsOneWidget,
    );
    expect(find.text('Crear'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });
}
