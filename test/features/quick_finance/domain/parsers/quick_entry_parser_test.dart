import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/domain/parsers/quick_entry_parser.dart';

void main() {
  const parser = QuickEntryParser();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Extrae el [ParsedEntry] o falla el test si el resultado no es [ParseSuccess].
  ParsedEntry success(String input) {
    final result = parser.parse(input);
    expect(
      result,
      isA<ParseSuccess>(),
      reason: 'Se esperaba ParseSuccess para: "$input"',
    );
    return (result as ParseSuccess).entry;
  }

  /// Verifica que el parse falla y devuelve la [ParseFailure].
  ParseFailure failure(String input) {
    final result = parser.parse(input);
    expect(
      result,
      isA<ParseFailure>(),
      reason: 'Se esperaba ParseFailure para: "$input"',
    );
    return result as ParseFailure;
  }

  // ---------------------------------------------------------------------------

  group('QuickEntryParser', () {
    // ── Signo ──────────────────────────────────────────────────────────────

    group('detección de signo', () {
      test('"-35 cena" → expense, 35.0, "cena"', () {
        final e = success('-35 cena');
        expect(e.type, TransactionType.expense);
        expect(e.amount, 35.0);
        expect(e.note, 'cena');
      });

      test('"+1500 salario" → income, 1500.0, "salario"', () {
        final e = success('+1500 salario');
        expect(e.type, TransactionType.income);
        expect(e.amount, 1500.0);
        expect(e.note, 'salario');
      });

      test('sin signo asume gasto: "50 café" → expense', () {
        final e = success('50 café');
        expect(e.type, TransactionType.expense);
        expect(e.amount, 50.0);
        expect(e.note, 'café');
      });

      test('espacio entre signo y número: "- 35 cena"', () {
        final e = success('- 35 cena');
        expect(e.type, TransactionType.expense);
        expect(e.amount, 35.0);
        expect(e.note, 'cena');
      });

      test('espacio entre "+" y número: "+ 200 bono"', () {
        final e = success('+ 200 bono');
        expect(e.type, TransactionType.income);
        expect(e.amount, 200.0);
        expect(e.note, 'bono');
      });
    });

    // ── Montos ─────────────────────────────────────────────────────────────

    group('parseado de montos', () {
      test('acepta decimales con punto: "-50.5 café" → 50.5', () {
        expect(success('-50.5 café').amount, 50.5);
      });

      test('acepta decimales con coma: "-35,50 almuerzo" → 35.5', () {
        final e = success('-35,50 almuerzo');
        expect(e.amount, 35.5);
        expect(e.type, TransactionType.expense);
      });

      test('coma decimal sin signo: "9,99 pan" → expense, 9.99', () {
        expect(success('9,99 pan').amount, closeTo(9.99, 0.001));
      });

      test('número grande: "+25000.99 bono" → 25000.99', () {
        final e = success('+25000.99 bono');
        expect(e.amount, 25000.99);
        expect(e.type, TransactionType.income);
      });

      test('entero sin decimales: "100 taxi" → 100.0', () {
        expect(success('100 taxi').amount, 100.0);
      });
    });

    // ── Símbolos de moneda ─────────────────────────────────────────────────

    group('símbolos de moneda', () {
      test('"\$50 grocery" → expense, 50.0, "grocery"', () {
        final e = success('\$50 grocery');
        expect(e.type, TransactionType.expense);
        expect(e.amount, 50.0);
        expect(e.note, 'grocery');
      });

      test('"€80 comida" → expense, 80.0, "comida"', () {
        final e = success('€80 comida');
        expect(e.amount, 80.0);
        expect(e.note, 'comida');
      });

      test('"+\$1500 salario" → income, 1500.0', () {
        final e = success('+\$1500 salario');
        expect(e.type, TransactionType.income);
        expect(e.amount, 1500.0);
      });

      test('"-£30 taxi" → expense, 30.0', () {
        final e = success('-£30 taxi');
        expect(e.type, TransactionType.expense);
        expect(e.amount, 30.0);
      });

      test('"+€1500,50 sueldo" → income, 1500.5', () {
        final e = success('+€1500,50 sueldo');
        expect(e.type, TransactionType.income);
        expect(e.amount, closeTo(1500.5, 0.001));
        expect(e.note, 'sueldo');
      });

      test('"¥5000 regalo" → expense, 5000.0', () {
        expect(success('¥5000 regalo').amount, 5000.0);
      });
    });

    // ── Categorías #tag ────────────────────────────────────────────────────

    group('categorías #tag', () {
      test('"-20 taxi #transporte" extrae category: "transporte"', () {
        final e = success('-20 taxi #transporte');
        expect(e.amount, 20.0);
        expect(e.note, 'taxi');
        expect(e.category, 'transporte');
      });

      test('tag al inicio: "#food -35 cena"', () {
        final e = success('#food -35 cena');
        expect(e.amount, 35.0);
        expect(e.note, 'cena');
        expect(e.category, 'food');
      });

      test('solo tag sin nota → nota por defecto', () {
        final e = success('-100 #deudas');
        expect(e.amount, 100.0);
        expect(e.note, 'Sin descripción');
        expect(e.category, 'deudas');
      });

      test('múltiples tags → usa la primera', () {
        final e = success('-50 pizza #comida #salida');
        expect(e.category, 'comida');
        expect(e.note, 'pizza');
      });

      test('sin tag → category es null', () {
        expect(success('-50 pizza').category, isNull);
      });
    });

    // ── Nota por defecto ───────────────────────────────────────────────────

    group('nota por defecto', () {
      test('"-200" → "Sin descripción"', () {
        final e = success('-200');
        expect(e.note, 'Sin descripción');
        expect(e.type, TransactionType.expense);
        expect(e.amount, 200.0);
      });

      test('"100" → expense, "Sin descripción"', () {
        final e = success('100');
        expect(e.type, TransactionType.expense);
        expect(e.note, 'Sin descripción');
      });

      test('"+100" → income, "Sin descripción"', () {
        final e = success('+100');
        expect(e.type, TransactionType.income);
        expect(e.note, 'Sin descripción');
      });

      test('"\$50" → "Sin descripción"', () {
        expect(success('\$50').note, 'Sin descripción');
      });
    });

    // ── Espacios y bordes ──────────────────────────────────────────────────

    group('espacios y bordes', () {
      test('espacios alrededor: "  -35  cena  "', () {
        final e = success('  -35  cena  ');
        expect(e.type, TransactionType.expense);
        expect(e.amount, 35.0);
        expect(e.note, 'cena');
      });

      test('nota con múltiples palabras: "-15 taxi del aeropuerto"', () {
        expect(success('-15 taxi del aeropuerto').note, 'taxi del aeropuerto');
      });

      test('nota con acentos y ñ: "+200 nómina extraordinaria"', () {
        final e = success('+200 nómina extraordinaria');
        expect(e.note, 'nómina extraordinaria');
        expect(e.type, TransactionType.income);
      });
    });

    // ── Entradas inválidas → ParseFailure ─────────────────────────────────

    group('entradas inválidas', () {
      test('vacío → ParseFailure con razón no vacía', () {
        final f = failure('');
        expect(f.reason, isNotEmpty);
      });

      test('solo espacios → ParseFailure', () {
        expect(parser.parse('   '), isA<ParseFailure>());
      });

      test('solo texto sin número → ParseFailure con mención de "monto"', () {
        final f = failure('café');
        expect(f.reason.toLowerCase(), contains('monto'));
      });

      test('solo signo "-" → ParseFailure', () {
        expect(parser.parse('-'), isA<ParseFailure>());
      });

      test('solo signo "+" → ParseFailure', () {
        expect(parser.parse('+'), isA<ParseFailure>());
      });

      test('monto cero: "0 cena" → ParseFailure', () {
        final f = failure('0 cena');
        expect(f.reason.toLowerCase(), contains('mayor'));
      });

      test('monto cero con coma: "0,0 algo" → ParseFailure', () {
        expect(parser.parse('0,0 algo'), isA<ParseFailure>());
      });

      test('solo símbolo de moneda "\$" → ParseFailure', () {
        expect(parser.parse('\$'), isA<ParseFailure>());
      });

      test('solo símbolo de moneda "€" → ParseFailure', () {
        expect(parser.parse('€'), isA<ParseFailure>());
      });

      test('solo #tag sin monto → ParseFailure', () {
        expect(parser.parse('#comida'), isA<ParseFailure>());
      });

      test('texto aleatorio sin número → ParseFailure', () {
        expect(parser.parse('hola mundo'), isA<ParseFailure>());
      });
    });

    // ── ParsedEntry equality & hashCode ───────────────────────────────────

    group('ParsedEntry equality', () {
      test('dos entradas iguales son iguales', () {
        const a = ParsedEntry(
          type: TransactionType.expense,
          amount: 35,
          note: 'cena',
        );
        const b = ParsedEntry(
          type: TransactionType.expense,
          amount: 35,
          note: 'cena',
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('category distinta → no iguales', () {
        const a = ParsedEntry(
          type: TransactionType.expense,
          amount: 35,
          note: 'cena',
          category: 'food',
        );
        const b = ParsedEntry(
          type: TransactionType.expense,
          amount: 35,
          note: 'cena',
        );
        expect(a, isNot(equals(b)));
      });

      test('toString contiene todos los campos', () {
        const entry = ParsedEntry(
          type: TransactionType.income,
          amount: 100,
          note: 'salario',
          category: 'trabajo',
        );
        final s = entry.toString();
        expect(s, contains('income'));
        expect(s, contains('100.0'));
        expect(s, contains('salario'));
        expect(s, contains('trabajo'));
      });
    });

    // ── ParseResult sealed class ───────────────────────────────────────────

    group('ParseResult sealed class', () {
      test('parse exitoso retorna ParseSuccess', () {
        expect(parser.parse('-50 café'), isA<ParseSuccess>());
      });

      test('parse fallido retorna ParseFailure', () {
        expect(parser.parse(''), isA<ParseFailure>());
      });

      test('switch exhaustivo funciona en Dart 3', () {
        String output;
        switch (parser.parse('-50 café')) {
          case ParseSuccess(:final entry):
            output = 'ok:${entry.amount}';
          case ParseFailure(:final reason):
            output = 'fail:$reason';
        }
        expect(output, 'ok:50.0');
      });

      test('ParseFailure expone razón legible', () {
        final f = failure('abc');
        expect(f.reason, isNotEmpty);
      });
    });
  });
}
