import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/domain/parsers/quick_entry_parser.dart';

void main() {
  const parser = QuickEntryParser();

  group('QuickEntryParser', () {
    group('detección de signo', () {
      test('"-35 cena" → expense, 35.0, "cena"', () {
        final result = parser.parse('-35 cena');
        expect(result, isNotNull);
        expect(result!.type, TransactionType.expense);
        expect(result.amount, 35.0);
        expect(result.note, 'cena');
      });

      test('"+1500 salario" → income, 1500.0, "salario"', () {
        final result = parser.parse('+1500 salario');
        expect(result, isNotNull);
        expect(result!.type, TransactionType.income);
        expect(result.amount, 1500.0);
        expect(result.note, 'salario');
      });

      test('sin signo asume gasto: "50 café" → expense', () {
        final result = parser.parse('50 café');
        expect(result, isNotNull);
        expect(result!.type, TransactionType.expense);
        expect(result.amount, 50.0);
        expect(result.note, 'café');
      });
    });

    group('casos del usuario — Día 2', () {
      test('"+500 salario" → income, 500.0, "salario"', () {
        final result = parser.parse('+500 salario');
        expect(result, isNotNull);
        expect(result!.type, TransactionType.income);
        expect(result.amount, 500.0);
        expect(result.note, 'salario');
      });

      test('"-80 comida" → expense, 80.0, "comida"', () {
        final result = parser.parse('-80 comida');
        expect(result, isNotNull);
        expect(result!.type, TransactionType.expense);
        expect(result.amount, 80.0);
        expect(result.note, 'comida');
      });

      test('"120 taxi" → expense, 120.0, "taxi"', () {
        final result = parser.parse('120 taxi');
        expect(result, isNotNull);
        expect(result!.type, TransactionType.expense);
        expect(result.amount, 120.0);
        expect(result.note, 'taxi');
      });
    });

    group('parseado de montos', () {
      test('acepta decimales: "-50.5 café" → 50.5', () {
        final result = parser.parse('-50.5 café');
        expect(result, isNotNull);
        expect(result!.amount, 50.5);
      });

      test('acepta decimales sin trailing: "100. comida" → 100.0', () {
        final result = parser.parse('100. comida');
        expect(result, isNotNull);
        expect(result!.amount, 100.0);
      });

      test('número grande: "+25000.99 bono" → 25000.99', () {
        final result = parser.parse('+25000.99 bono');
        expect(result, isNotNull);
        expect(result!.amount, 25000.99);
        expect(result.type, TransactionType.income);
      });
    });

    group('nota por defecto', () {
      test('sin nota: "-200" → "Sin descripción"', () {
        final result = parser.parse('-200');
        expect(result, isNotNull);
        expect(result!.note, 'Sin descripción');
        expect(result.type, TransactionType.expense);
        expect(result.amount, 200.0);
      });

      test('sin nota y sin signo: "100" → expense, "Sin descripción"', () {
        final result = parser.parse('100');
        expect(result, isNotNull);
        expect(result!.type, TransactionType.expense);
        expect(result.amount, 100.0);
        expect(result.note, 'Sin descripción');
      });

      test('sin nota con +: "+100" → income, "Sin descripción"', () {
        final result = parser.parse('+100');
        expect(result, isNotNull);
        expect(result!.type, TransactionType.income);
        expect(result.amount, 100.0);
        expect(result.note, 'Sin descripción');
      });
    });

    group('espacios y bordes', () {
      test('espacios alrededor: "  -35  cena  " → funciona', () {
        final result = parser.parse('  -35  cena  ');
        expect(result, isNotNull);
        expect(result!.type, TransactionType.expense);
        expect(result.amount, 35.0);
        expect(result.note, 'cena');
      });

      test('espacio entre signo y número: "- 35 cena"', () {
        final result = parser.parse('- 35 cena');
        expect(result, isNotNull);
        expect(result!.type, TransactionType.expense);
        expect(result.amount, 35.0);
        expect(result.note, 'cena');
      });

      test('nota con múltiples palabras: "-15 taxi del aeropuerto"', () {
        final result = parser.parse('-15 taxi del aeropuerto');
        expect(result, isNotNull);
        expect(result!.note, 'taxi del aeropuerto');
      });
    });

    group('entradas inválidas', () {
      test('vacío devuelve null', () {
        expect(parser.parse(''), isNull);
      });

      test('solo espacios devuelve null', () {
        expect(parser.parse('   '), isNull);
      });

      test('solo texto sin número devuelve null', () {
        expect(parser.parse('café'), isNull);
      });

      test('solo signo devuelve null', () {
        expect(parser.parse('-'), isNull);
        expect(parser.parse('+'), isNull);
      });
    });

    group('igualdad de ParsedEntry', () {
      test('dos entradas iguales son iguales', () {
        final a = ParsedEntry(
          type: TransactionType.expense,
          amount: 35.0,
          note: 'cena',
        );
        final b = ParsedEntry(
          type: TransactionType.expense,
          amount: 35.0,
          note: 'cena',
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('toString tiene formato legible', () {
        final entry = ParsedEntry(
          type: TransactionType.income,
          amount: 100.0,
          note: 'salario',
        );
        expect(
          entry.toString(),
          'ParsedEntry(type: TransactionType.income, amount: 100.0, note: "salario")',
        );
      });
    });
  });
}
