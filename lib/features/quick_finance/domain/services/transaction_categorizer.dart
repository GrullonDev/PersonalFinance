import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/auto_capture/domain/merchant_categorizer.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';

/// Detecta la categoría de un movimiento a partir de lo que escribió el
/// usuario (normalmente sólo el lugar: "Starbucks", "Uber", "Paiz").
///
/// Orden: lo que el usuario ya usó antes para esa misma descripción →
/// palabras clave locales → IA (opcional). Devuelve un identificador corto
/// (`comida`, `transporte`…) o `null` si no hay certeza.
class TransactionCategorizer {
  TransactionCategorizer({
    MerchantCategorizer keywords = const MerchantCategorizer(),
    Future<String?> Function(String description)? ai,
    this.aiTimeout = const Duration(seconds: 5),
  }) : _keywords = keywords,
       _ai = ai;

  final MerchantCategorizer _keywords;
  final Future<String?> Function(String description)? _ai;
  final Duration aiTimeout;

  bool get hasAi => _ai != null;

  static const Map<String, String> _displayNames = {
    'comida': 'Comida',
    'supermercado': 'Supermercado',
    'transporte': 'Transporte',
    'gasolina': 'Gasolina',
    'suscripciones': 'Suscripciones',
    'compras': 'Compras',
    'salud': 'Salud',
    'servicios': 'Servicios',
    'entretenimiento': 'Entretenimiento',
    'educacion': 'Educación',
    'hogar': 'Hogar',
    'negocio': 'Negocio',
    'creditos': 'Créditos',
    'salario': 'Salario',
    'reembolso': 'Reembolso',
    'transferencia': 'Transferencia',
    'ingresos': 'Ingresos',
  };

  // Nombres que devuelve la IA → identificadores usados en la app.
  static const Map<String, String> _aliases = {
    'alimentacion': 'comida',
    'alimentos': 'comida',
    'restaurantes': 'comida',
    'credito': 'creditos',
    'deudas': 'creditos',
    'educación': 'educacion',
  };

  static const Set<String> _generic = {'otros', 'otro', 'sin_categoria'};
  static const String _noDescription = 'sin descripción';

  /// Categoría local e inmediata (historial + palabras clave), sin red.
  String? categorizeLocally({
    required String note,
    required TransactionType type,
    Iterable<TransactionEntity> history = const [],
  }) {
    final key = _noteKey(note);
    if (key.isEmpty || key == _noDescription) return null;

    // 1. Lo que el usuario ya asignó antes a esta misma descripción.
    for (final t in history) {
      final category = t.categoryId;
      if (category == null || category.trim().isEmpty) continue;
      if (t.type == type && _noteKey(t.note) == key) return category;
    }

    // 2. Palabras clave (comercios y palabras comunes).
    final local = _keywords.categorize(note, type: type);
    if (local != null) return local;

    // 3. La nota menciona directamente una categoría conocida ("pago luz").
    for (final word in key.split(' ')) {
      final slug = normalize(word);
      if (slug != null && _displayNames.containsKey(slug)) return slug;
    }

    return type == TransactionType.income ? 'ingresos' : null;
  }

  /// Pregunta a la IA; `null` si no hay IA, tarda demasiado o no sabe.
  Future<String?> categorizeWithAi(String note) async {
    final ai = _ai;
    final key = _noteKey(note);
    if (ai == null || key.isEmpty || key == _noDescription) return null;
    try {
      return normalize(await ai(note.trim()).timeout(aiTimeout));
    } catch (_) {
      return null;
    }
  }

  /// Convierte un nombre libre ("Alimentación", "Transporte ") en el
  /// identificador de la app; `null` si es genérico ("Otros") o vacío.
  static String? normalize(String? raw) {
    if (raw == null) return null;
    var slug = raw.trim().toLowerCase().replaceFirst(RegExp('^#'), '');
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    accents.forEach((from, to) => slug = slug.replaceAll(from, to));
    slug = slug
        .replaceAll(RegExp(r'[^a-z0-9ñ]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (slug.isEmpty || _generic.contains(slug)) return null;
    return _aliases[slug] ?? slug;
  }

  /// Nombre legible para mostrar o para crear la categoría ("educacion" →
  /// "Educación").
  static String displayName(String slug) {
    final known = _displayNames[slug];
    if (known != null) return known;
    final text = slug.replaceAll('_', ' ').trim();
    if (text.isEmpty) return slug;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String _noteKey(String note) =>
      note.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
