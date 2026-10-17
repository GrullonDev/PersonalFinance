import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/ai_chat/domain/ai_chat_quota.dart';
import 'package:personal_finance/features/ai_chat/domain/financial_context_builder.dart';
import 'package:personal_finance/features/ai_chat/presentation/widgets/ai_message_text.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';

TransactionEntity _tx(
  TransactionType type,
  double amount,
  String? category,
  DateTime at,
) => TransactionEntity(
  id: '$amount$category',
  userId: 'u',
  type: type,
  amount: amount,
  note: 'x',
  categoryId: category,
  createdAt: at,
  updatedAt: at,
  syncStatus: SyncStatus.synced,
  version: 1,
  deviceId: 'd',
);

void main() {
  group('parseAiMessage', () {
    test('convierte títulos, viñetas y listas numeradas', () {
      final blocks = parseAiMessage(
        '## Tu resumen\n'
        'Vas bien este mes.\n\n'
        '- Gastas **Q500** en comida\n'
        '* Reduce delivery\n'
        '1. Define un tope\n'
        '**Paso de hoy:**\n'
        'Anota tus gastos.',
      );
      expect(blocks[0], isA<AiHeading>());
      expect((blocks[0] as AiHeading).text, 'Tu resumen');
      expect((blocks[1] as AiParagraph).text, 'Vas bien este mes.');
      expect((blocks[2] as AiListItem).text, 'Gastas **Q500** en comida');
      expect((blocks[3] as AiListItem).marker, '•');
      expect((blocks[4] as AiListItem).marker, '1.');
      expect((blocks[5] as AiHeading).text, 'Paso de hoy:');
      expect((blocks[6] as AiParagraph).text, 'Anota tus gastos.');
    });

    test('las negritas se muestran sin asteriscos', () {
      final spans = parseInlineBold(
        'Gastas **Q500** al mes',
        const TextStyle(),
      );
      expect(spans.map((s) => s.text).join(), 'Gastas Q500 al mes');
      expect(spans[1].style?.fontWeight, FontWeight.w700);
    });
  });

  group('AiChatQuota', () {
    test(
      'permite 3 preguntas gratis por día y se reinicia al día siguiente',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        var now = DateTime(2026, 10, 5, 9);
        final quota = AiChatQuota(prefs, now: () => now);

        expect(quota.remainingToday, 3);
        await quota.consume();
        await quota.consume();
        await quota.consume();
        expect(quota.hasRemaining, isFalse);

        now = DateTime(2026, 10, 6, 8);
        expect(quota.remainingToday, 3);
      },
    );
  });

  group('FinancialContextBuilder', () {
    test('resume ingresos, gastos y categorías del mes', () {
      final now = DateTime(2026, 10, 15);
      final text =
          const FinancialContextBuilder().build(
            [
              _tx(
                TransactionType.income,
                5000,
                'salario',
                DateTime(2026, 10, 1),
              ),
              _tx(
                TransactionType.expense,
                600,
                'comida',
                DateTime(2026, 10, 3),
              ),
              _tx(
                TransactionType.expense,
                400,
                'transporte',
                DateTime(2026, 10, 4),
              ),
              _tx(
                TransactionType.expense,
                999,
                'comida',
                DateTime(2026, 9, 30),
              ),
            ],
            currencySymbol: 'Q',
            now: now,
          )!;

      expect(text, contains('Ingresos: Q5000.00'));
      expect(text, contains('Gastos: Q1000.00 en 2 movimientos'));
      expect(text, contains('Comida Q600.00 (60%)'));
      expect(text, isNot(contains('999')));
    });

    test('sin movimientos del mes no envía contexto', () {
      expect(
        const FinancialContextBuilder().build(const [], currencySymbol: 'Q'),
        isNull,
      );
    });
  });
}
