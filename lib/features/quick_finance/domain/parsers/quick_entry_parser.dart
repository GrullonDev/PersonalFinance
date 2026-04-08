import 'package:personal_finance/core/constants/enums.dart';

/// Resultado del parsing de una entrada rápida.
///
/// Contiene el tipo de transacción, el monto y la nota extraídos
/// del texto crudo ingresado por el usuario.
class ParsedEntry {
  final TransactionType type;
  final double amount;
  final String note;

  const ParsedEntry({
    required this.type,
    required this.amount,
    required this.note,
  });

  @override
  String toString() =>
      'ParsedEntry(type: $type, amount: $amount, note: "$note")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedEntry &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          amount == other.amount &&
          note == other.note;

  @override
  int get hashCode => type.hashCode ^ amount.hashCode ^ note.hashCode;
}

/// Parser por reglas para entrada rápida de transacciones.
///
/// Reglas:
/// - Detecta signo `+` (ingreso) o `-` (gasto).
/// - Si no hay signo, asume **gasto** por defecto.
/// - El primer número encontrado es el **monto** (acepta decimales).
/// - El texto restante se usa como **nota**.
/// - Si no hay nota, se asigna "Sin descripción".
/// - Devuelve `null` si no logra extraer un monto válido.
///
/// Ejemplos válidos:
///   "-35 cena"       → expense, 35.0, "cena"
///   "+1500 salario"  → income, 1500.0, "salario"
///   "50.5 café"      → expense, 50.5, "café"     (sin signo = gasto)
///   "-200"           → expense, 200.0, "Sin descripción"
///   "100"            → expense, 100.0, "Sin descripción"
///   "+100"           → income, 100.0, "Sin descripción"
class QuickEntryParser {
  /// Regex principal:
  ///   Grupo 1: signo opcional (+/-)
  ///   Grupo 2: número con decimales opcionales
  ///   Grupo 3: texto restante (nota)
  static final RegExp _pattern = RegExp(
    r'^\s*([+-])?\s*(\d+\.?\d*)\s*(.*?)\s*$',
  );

  const QuickEntryParser();

  /// Parsea el texto [input] y devuelve un [ParsedEntry] o `null`
  /// si el input es inválido (vacío, sin número, etc.)
  ParsedEntry? parse(String input) {
    if (input.trim().isEmpty) return null;

    final match = _pattern.firstMatch(input);
    if (match == null) return null;

    final sign = match.group(1); // '+', '-', o null
    final rawAmount = match.group(2); // '35', '50.5', etc.
    final rawNote = match.group(3); // 'cena', '', etc.

    // Parsear el monto
    final amount = double.tryParse(rawAmount ?? '');
    if (amount == null || amount <= 0) return null;

    // Determinar tipo: + → income, - → expense, nada → expense
    final TransactionType type;
    if (sign == '+') {
      type = TransactionType.income;
    } else {
      // '-' explícito o sin signo → gasto por defecto
      type = TransactionType.expense;
    }

    // Nota: si está vacía, usar placeholder
    final note = (rawNote != null && rawNote.trim().isNotEmpty)
        ? rawNote.trim()
        : 'Sin descripción';

    return ParsedEntry(
      type: type,
      amount: amount,
      note: note,
    );
  }
}
