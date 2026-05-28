import 'package:personal_finance/core/constants/enums.dart';

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

sealed class ParseResult {
  const ParseResult();
}

final class ParseSuccess extends ParseResult {
  final ParsedEntry entry;
  const ParseSuccess(this.entry);
}

final class ParseFailure extends ParseResult {
  final String reason;
  const ParseFailure(this.reason);
}

// ---------------------------------------------------------------------------
// ParsedEntry
// ---------------------------------------------------------------------------

/// Datos extraídos de una entrada rápida válida.
class ParsedEntry {
  final TransactionType type;
  final double amount;
  final String note;

  /// Primera categoría `#tag` encontrada en la entrada, si existía.
  final String? category;

  const ParsedEntry({
    required this.type,
    required this.amount,
    required this.note,
    this.category,
  });

  @override
  String toString() =>
      'ParsedEntry(type: $type, amount: $amount, note: "$note", category: $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedEntry &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          amount == other.amount &&
          note == other.note &&
          category == other.category;

  @override
  int get hashCode =>
      type.hashCode ^ amount.hashCode ^ note.hashCode ^ category.hashCode;
}

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

/// Parser robusto para entrada rápida de transacciones financieras.
///
/// ### Formato aceptado
/// ```
/// [signo] [símbolo] monto [nota] [#categoría]
/// ```
///
/// **Signo** (`+` / `-`): opcional, antes del símbolo o del monto.
/// - `+` → ingreso; `-` o ausente → gasto.
///
/// **Símbolo de moneda**: `$`, `€`, `£`, `¥`, `₹`, `₽`, `¢`, `₩`, `₪`, `฿`.
/// Ignorado al parsear; puede ir antes o después del número.
///
/// **Monto**: primer número encontrado tras el signo.
/// Acepta `.` o `,` como separador decimal.
///
/// **Nota**: texto restante después del monto (sin tags).
/// Si está vacía se usa `"Sin descripción"`.
///
/// **Categoría** (`#tag`): primera etiqueta `#palabra`; se extrae y elimina
/// del texto antes de procesar nota y monto.
///
/// ### Ejemplos válidos
/// ```
/// "-35 cena"            → expense, 35.0,   "cena"
/// "+1500 salario"       → income,  1500.0, "salario"
/// "50 café"             → expense, 50.0,   "café"
/// "-35,50 almuerzo"     → expense, 35.5,   "almuerzo"
/// "$50 grocery"         → expense, 50.0,   "grocery"
/// "+€1500 sueldo"       → income,  1500.0, "sueldo"
/// "20 taxi #transporte" → expense, 20.0,   "taxi", category:"transporte"
/// "-200"                → expense, 200.0,  "Sin descripción"
/// ```
class QuickEntryParser {
  static const _defaultNote = 'Sin descripción';

  static final _tagPattern = RegExp(r'#(\w+)');
  static final _currencyPattern = RegExp(r'[$€£¥₹₽¢₩₪฿]');
  static final _signPattern = RegExp(r'^([+-])');
  // Acepta número con separador decimal punto o coma
  static final _amountPattern = RegExp(r'(\d+(?:[.,]\d+)?)');

  const QuickEntryParser();

  /// Parsea [input] y devuelve [ParseSuccess] con los datos o
  /// [ParseFailure] con la razón del error.
  ParseResult parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ParseFailure('La entrada no puede estar vacía');
    }

    var working = trimmed;

    // 1 ── Extraer etiquetas #tag
    final tags =
        _tagPattern.allMatches(working).map((m) => m.group(1)!).toList();
    working = working.replaceAll(_tagPattern, '').trim();

    if (working.isEmpty) {
      return const ParseFailure('No se encontró un monto válido');
    }

    // 2 ── Extraer signo (+ / -)
    var type = TransactionType.expense; // gasto por defecto sin signo
    final signMatch = _signPattern.firstMatch(working);
    if (signMatch != null) {
      type =
          signMatch.group(1) == '+'
              ? TransactionType.income
              : TransactionType.expense;
      working = working.substring(1).trim();
    }

    // 3 ── Eliminar símbolos de moneda (antes o después del número)
    working = working.replaceAll(_currencyPattern, '').trim();

    if (working.isEmpty) {
      return const ParseFailure('No se encontró un monto válido');
    }

    // 4 ── Extraer el primer número; acepta '.' o ',' como decimal
    final amountMatch = _amountPattern.firstMatch(working);
    if (amountMatch == null) {
      return const ParseFailure('No se encontró un monto válido');
    }

    final rawAmount = amountMatch.group(1)!.replaceAll(',', '.');
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) {
      return const ParseFailure('El monto debe ser mayor que cero');
    }

    // 5 ── Nota = todo lo que queda después del monto
    final noteRaw = working.substring(amountMatch.end).trim();
    final note = noteRaw.isEmpty ? _defaultNote : noteRaw;

    return ParseSuccess(
      ParsedEntry(
        type: type,
        amount: amount,
        note: note,
        category: tags.isNotEmpty ? tags.first : null,
      ),
    );
  }
}
