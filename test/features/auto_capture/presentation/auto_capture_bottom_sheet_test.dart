import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/auto_capture/presentation/auto_capture_bottom_sheet.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_event.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_state.dart';
import 'package:personal_finance/core/constants/enums.dart';

/// Minimal fake that avoids instantiating heavy dependencies (Firebase,
/// Hive, platform channels) during widget-test loading.
class _FakeBloc extends Fake implements QuickFinanceBloc {
  final List<QuickFinanceEvent> events = [];

  @override
  QuickFinanceState get state => const QuickFinanceState();

  @override
  Stream<QuickFinanceState> get stream => const Stream.empty();

  @override
  bool get isClosed => false;

  @override
  void add(QuickFinanceEvent event) => events.add(event);

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final capture = AutoCapturedTransaction(
    type: TransactionType.expense,
    amount: 75.50,
    note: 'Uber',
    occurredAt: DateTime(2026, 9, 25),
    sourceLabel: 'Google Wallet',
    category: 'transporte',
  );

  Widget buildSheet(_FakeBloc bloc) => MaterialApp(
    home: BlocProvider<QuickFinanceBloc>.value(
      value: bloc,
      child: Scaffold(body: AutoCaptureBottomSheet(capture: capture)),
    ),
  );

  testWidgets('shows source label badge', (tester) async {
    await tester.pumpWidget(buildSheet(_FakeBloc()));
    expect(find.text('Google Wallet'), findsOneWidget);
  });

  testWidgets('shows pre-filled amount', (tester) async {
    await tester.pumpWidget(buildSheet(_FakeBloc()));
    expect(find.text('75.50'), findsOneWidget);
  });

  testWidgets('shows pre-filled note', (tester) async {
    await tester.pumpWidget(buildSheet(_FakeBloc()));
    expect(find.text('Uber'), findsOneWidget);
  });

  testWidgets('Confirmar button dispatches AutoCaptureConfirmed', (tester) async {
    final bloc = _FakeBloc();
    await tester.pumpWidget(buildSheet(bloc));
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    expect(
      bloc.events.whereType<AutoCaptureConfirmed>().length,
      1,
      reason: 'Expected exactly one AutoCaptureConfirmed event',
    );
  });

  testWidgets('Descartar button dispatches AutoCaptureDismissed', (tester) async {
    final bloc = _FakeBloc();
    await tester.pumpWidget(buildSheet(bloc));
    await tester.tap(find.text('Descartar'));
    await tester.pump();
    expect(
      bloc.events.whereType<AutoCaptureDismissed>().length,
      1,
      reason: 'Expected exactly one AutoCaptureDismissed event',
    );
  });

  testWidgets('edited note is included in AutoCaptureConfirmed', (tester) async {
    final bloc = _FakeBloc();
    await tester.pumpWidget(buildSheet(bloc));
    final noteField = find.widgetWithText(TextFormField, 'Uber');
    await tester.enterText(noteField, 'Uber Eats');
    await tester.tap(find.text('Confirmar'));
    await tester.pump();

    final confirmed = bloc.events.whereType<AutoCaptureConfirmed>().first;
    expect(confirmed.editedNote, 'Uber Eats');
  });

  testWidgets('edited amount is included in AutoCaptureConfirmed', (tester) async {
    final bloc = _FakeBloc();
    await tester.pumpWidget(buildSheet(bloc));
    await tester.enterText(find.widgetWithText(TextFormField, '75.50'), '99.99');
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    final confirmed = bloc.events.whereType<AutoCaptureConfirmed>().first;
    expect(confirmed.editedAmount, 99.99);
  });

  testWidgets('dismiss does not dispatch AutoCaptureConfirmed', (tester) async {
    final bloc = _FakeBloc();
    await tester.pumpWidget(buildSheet(bloc));
    await tester.tap(find.text('Descartar'));
    await tester.pump();
    expect(bloc.events.whereType<AutoCaptureConfirmed>(), isEmpty);
  });
}
