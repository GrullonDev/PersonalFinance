import 'package:equatable/equatable.dart';
import 'package:personal_finance/core/constants/enums.dart';

/// Pago detectado a partir de una notificación (Google Wallet, banco, SMS)
/// o de un atajo de Apple Pay.
class ParsedPayment extends Equatable {
  final TransactionType type;
  final double amount;

  /// Comercio o descripción; vacío si no se pudo identificar.
  final String merchant;

  const ParsedPayment({
    required this.type,
    required this.amount,
    required this.merchant,
  });

  @override
  List<Object?> get props => [type, amount, merchant];
}

/// Interpreta el texto de una notificación de pago.
///
/// Sólo devuelve un resultado cuando el texto tiene un monto **y** una
/// palabra clave clara de gasto o ingreso; ante la duda devuelve `null`
/// para que el usuario registre el movimiento manualmente.
class PaymentNotificationParser {
  const PaymentNotificationParser();

  /// Apps de billetera: cualquier notificación con monto se trata como gasto
  /// salvo que diga explícitamente que es un ingreso o reembolso.
  static const Set<String> walletPackages = {
    'com.google.android.apps.walletnfcrel', // Google Wallet
    'com.google.android.apps.nbu.paisa.user', // Google Pay
    'com.samsung.android.spay', // Samsung Wallet
  };

  static const List<String> _incomeKeywords = [
    'recibiste',
    'has recibido',
    'te enviaron',
    'te envió',
    'te envio',
    'transferencia recibida',
    'depósito',
    'deposito',
    'acreditado',
    'acreditamos',
    'abonamos',
    'abono a tu cuenta',
    'reembolso',
    'devolución',
    'devolucion',
    'pago recibido',
    'you received',
    'refund',
    'deposit',
  ];

  static const List<String> _expenseKeywords = [
    'pagaste',
    'has pagado',
    'pago realizado',
    'pago aprobado',
    'pago con',
    'compra',
    'consumo',
    'cargo',
    'débito',
    'debito',
    'retiro',
    'transferencia enviada',
    'enviaste',
    'you paid',
    'paid',
    'purchase',
    'payment',
    'spent',
  ];

  static final RegExp _amount = RegExp(
    // El símbolo no puede ir pegado a una letra: "el 25" no es "L 25".
    r'(?<![A-Za-zÁÉÍÓÚÑáéíóúñ])(?:(?:GTQ|USD|MXN|EUR|COP|PEN|CLP|ARS|HNL|CRC|DOP|Q|\$|€|£|US\$|L|₡|S/)\s?)'
    r'(\d{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)'
    r'|(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})|\d+[.,]\d{1,2})\s?(?:GTQ|USD|MXN|EUR|quetzales|dólares|dolares)',
    caseSensitive: false,
  );

  static final RegExp _merchantAfter = RegExp(
    r'\b(?:en|at|a|to|con)\s+([A-Za-zÁÉÍÓÚÑáéíóúñ0-9&\x27*.\- ]{2,40}?)'
    r'(?=\s*(?:[,.;:!]\s|[,.;:!]$|$|\s(?:el|on|con|with|por|for|tarjeta|card|\d)))',
    caseSensitive: false,
  );

  ParsedPayment? parse({
    required String packageName,
    required String title,
    required String text,
  }) {
    final full = '$title. $text'.trim();
    final lower = full.toLowerCase();
    final amount = parseAmount(full);
    if (amount == null || amount <= 0) return null;

    final isIncome = _incomeKeywords.any(lower.contains);
    final isExpense = _expenseKeywords.any(lower.contains);

    final TransactionType type;
    if (isIncome && !_startsWithExpense(lower)) {
      type = TransactionType.income;
    } else if (isExpense || walletPackages.contains(packageName)) {
      type = TransactionType.expense;
    } else {
      return null;
    }

    return ParsedPayment(
      type: type,
      amount: amount,
      merchant: extractMerchant(text, title: title),
    );
  }

  /// "Compra ... reembolso" no es un ingreso: gana la palabra que aparece primero.
  bool _startsWithExpense(String lower) {
    int first(List<String> words) => words
        .map(lower.indexOf)
        .where((i) => i >= 0)
        .fold<int>(1 << 30, (a, b) => a < b ? a : b);
    return first(_expenseKeywords) < first(_incomeKeywords);
  }

  /// Extrae el primer monto del texto, aceptando "Q1,234.50", "$ 12,50",
  /// "1.234,50 GTQ" o un número suelto (útil para los atajos de iOS).
  static double? parseAmount(String input) {
    final match = _amount.firstMatch(input);
    String? raw = match?.group(1) ?? match?.group(2);
    raw ??= RegExp(r'\d+(?:[.,]\d+)*').firstMatch(input)?.group(0);
    if (raw == null) return null;
    return _normalizeNumber(raw.replaceAll(' ', ''));
  }

  static double? _normalizeNumber(String raw) {
    final lastDot = raw.lastIndexOf('.');
    final lastComma = raw.lastIndexOf(',');
    String normalized;
    if (lastDot >= 0 && lastComma >= 0) {
      // El separador que aparece último es el decimal.
      normalized =
          lastDot > lastComma
              ? raw.replaceAll(',', '')
              : raw.replaceAll('.', '').replaceAll(',', '.');
    } else if (lastComma >= 0) {
      final decimals = raw.length - lastComma - 1;
      normalized =
          (decimals == 3 && raw.indexOf(',') == lastComma)
              ? raw.replaceAll(',', '')
              : raw.replaceAll(',', '.');
    } else if (lastDot >= 0) {
      final decimals = raw.length - lastDot - 1;
      normalized =
          (decimals == 3 && raw.indexOf('.') == lastDot && raw.length > 4)
              ? raw.replaceAll('.', '')
              : raw;
      if ('.'.allMatches(normalized).length > 1) {
        normalized = normalized.replaceAll('.', '');
      }
    } else {
      normalized = raw;
    }
    return double.tryParse(normalized);
  }

  /// Busca el comercio después de "en/at/a/con"; si no lo encuentra usa
  /// el título de la notificación (Google Wallet pone ahí el comercio).
  static String extractMerchant(String text, {String title = ''}) {
    final withoutAmounts = text
        .replaceAll(_amount, ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    final match = _merchantAfter.firstMatch(withoutAmounts);
    var merchant = match?.group(1)?.trim() ?? '';
    if (merchant.isEmpty || _isGeneric(merchant)) {
      merchant = title.trim();
    }
    if (_isGeneric(merchant)) merchant = '';
    return merchant
        .replaceAll(RegExp(r'[*#]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isGeneric(String value) {
    final v = value.toLowerCase().trim();
    if (v.isEmpty) return true;
    const generic = [
      'google wallet',
      'google pay',
      'samsung wallet',
      'tu tarjeta',
      'tu cuenta',
      'your card',
      'compra',
      'pago',
      'notificación',
      'notificacion',
      'transacción',
      'transaccion',
    ];
    return generic.any((g) => v == g || v.startsWith('$g ')) ||
        RegExp(r'^[\d\s.,]+$').hasMatch(v);
  }
}
