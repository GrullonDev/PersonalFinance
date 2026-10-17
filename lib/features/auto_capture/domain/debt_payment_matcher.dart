import 'package:personal_finance/features/debts/domain/entities/debt.dart';

/// Reconoce cuándo un débito detectado automáticamente es el pago de una
/// deuda del usuario ("Pago a tarjeta Visa BI ****1234" → deuda "Visa BI").
///
/// Sólo responde cuando el texto habla de un pago/abono/cuota: una compra
/// hecha *con* la tarjeta no es un pago a la deuda.
class DebtPaymentMatcher {
  const DebtPaymentMatcher();

  static final RegExp _paymentSignal = RegExp(
    r'\b(?:pago|pagaste|abono|abonaste|abonado|cuota|amortizaci[oó]n|cancelaci[oó]n)\b',
  );

  static final RegExp _purchaseSignal = RegExp(
    r'\b(?:compra|consumo|transacci[oó]n aprobada|pago con|pagaste con)\b',
  );

  static final RegExp _debtWord = RegExp(
    r'\b(?:tarjeta|tc|pr[eé]stamo|cr[eé]dito|financiamiento|deuda|cuota|hipoteca)\b',
  );

  /// Palabras que describen el tipo de deuda pero no la identifican.
  static const Set<String> _stopwords = {
    'tarjeta',
    'tc',
    'credito',
    'prestamo',
    'deuda',
    'cuota',
    'pago',
    'abono',
    'banco',
    'cuenta',
    'de',
    'del',
    'la',
    'el',
    'los',
    'las',
    'mi',
    'mis',
    'su',
    'tu',
    'a',
    'en',
    'por',
    'con',
    'y',
    'financiamiento',
    'personal',
    'hipoteca',
    'hipotecario',
  };

  /// Devuelve la deuda que recibe el pago o `null` si no hay certeza.
  Debt? match(String text, List<Debt> debts) {
    final lower = _fold(text);
    if (!_paymentSignal.hasMatch(lower)) return null;
    if (_purchaseSignal.hasMatch(lower)) return null;

    final active =
        debts
            .where((d) => d.deletedAt == null && d.currentBalance > 0)
            .toList();
    if (active.isEmpty) return null;

    final textTokens = _tokens(lower);
    Debt? best;
    var bestScore = 0;
    var tie = false;
    for (final debt in active) {
      final nameTokens = _significant(_tokens(_fold(debt.name)));
      if (nameTokens.isEmpty) continue;
      final hits = nameTokens.where(textTokens.contains).length;
      // Todas las palabras del nombre, o un número de tarjeta (últimos 4).
      final cardDigits = nameTokens.any(
        (t) =>
            t.length == 4 && int.tryParse(t) != null && textTokens.contains(t),
      );
      if (hits < nameTokens.length && !cardDigits) continue;
      final score = hits * 10 + (cardDigits ? 50 : 0);
      if (score > bestScore) {
        best = debt;
        bestScore = score;
        tie = false;
      } else if (score == bestScore) {
        tie = true;
      }
    }
    if (best != null && !tie) return best;

    // "Pago a tarjeta de crédito": si sólo hay una deuda de ese tipo.
    if (_debtWord.hasMatch(lower) && active.length == 1) return active.first;
    return null;
  }

  static Set<String> _tokens(String value) =>
      value.split(RegExp(r'[^a-z0-9ñ]+')).where((t) => t.isNotEmpty).toSet();

  static Set<String> _significant(Set<String> tokens) =>
      tokens
          .where((t) => !_stopwords.contains(t) && (t.length >= 3 || _isNum(t)))
          .toSet();

  static bool _isNum(String t) => int.tryParse(t) != null;

  static String _fold(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u');
}
