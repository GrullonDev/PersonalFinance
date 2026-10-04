import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';

// ── Entidades de retorno ────────────────────────────────────────────────────

class ScannedFinancialDocument {
  final double? amount;
  final String? merchant;
  final String? date;
  final String? category;
  final String? description;

  const ScannedFinancialDocument({
    this.amount,
    this.merchant,
    this.date,
    this.category,
    this.description,
  });

  factory ScannedFinancialDocument.fromJson(Map<String, dynamic> json) =>
      ScannedFinancialDocument(
        amount: (json['amount'] as num?)?.toDouble(),
        merchant: json['merchant'] as String?,
        date: json['date'] as String?,
        category: json['category'] as String?,
        description: json['description'] as String?,
      );
}

class FinancialHealthScore {
  final int score;
  final String grade;
  final String summary;

  const FinancialHealthScore({
    required this.score,
    required this.grade,
    required this.summary,
  });

  factory FinancialHealthScore.fromJson(Map<String, dynamic> json) =>
      FinancialHealthScore(
        score: (json['score'] as num?)?.toInt() ?? 50,
        grade: json['grade'] as String? ?? 'C',
        summary: json['summary'] as String? ?? 'Sin evaluación disponible.',
      );

  factory FinancialHealthScore.fallback() => const FinancialHealthScore(
    score: 50,
    grade: 'C',
    summary:
        'Registra más transacciones para obtener tu puntaje de salud financiera.',
  );
}

// ── Interfaz Gemini ─────────────────────────────────────────────────────────

/// Interfaz para abstraer el cliente de Gemini y facilitar pruebas unitarias.
abstract class GeminiClient {
  Future<String?> generate(String prompt);
  Future<String?> generateMultiTurn(List<Content> contents);
}

/// Implementación real utilizando la clase final GenerativeModel de Firebase.
class FirebaseGeminiClient implements GeminiClient {
  final GenerativeModel _model;
  FirebaseGeminiClient(this._model);

  @override
  Future<String?> generate(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text;
  }

  @override
  Future<String?> generateMultiTurn(List<Content> contents) async {
    final response = await _model.generateContent(contents);
    return response.text;
  }
}

class VertexAiService {
  final GeminiClient _client;

  VertexAiService({GeminiClient? client})
    : _client =
          client ??
          FirebaseGeminiClient(
            FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash'),
          );

  /// Categoriza automáticamente un gasto según su título/descripción
  Future<String> getCategoryForExpense(String title) async {
    final prompt = '''
Eres un categorizador de gastos inteligente y preciso para una aplicación de finanzas personales.
Dada la descripción o título de un gasto, debes clasificarlo en EXACTAMENTE una de las siguientes categorías del sistema:
- Alimentación
- Transporte
- Hogar
- Entretenimiento
- Compras
- Salud
- Créditos
- Negocio
- Otros

Gasto a clasificar: "$title"

Responde únicamente con el nombre de la categoría elegida, exactamente como aparece en la lista anterior, sin puntuación adicional ni explicaciones.
''';

    try {
      final responseText = await _client.generate(prompt);
      final category = responseText?.trim() ?? 'Otros';

      final validCategories = [
        'Alimentación',
        'Transporte',
        'Hogar',
        'Entretenimiento',
        'Compras',
        'Salud',
        'Créditos',
        'Negocio',
        'Otros',
      ];

      for (final cat in validCategories) {
        if (category.toLowerCase().contains(cat.toLowerCase())) {
          return cat;
        }
      }
      return 'Otros';
    } catch (e) {
      developer.log('Error en auto-categorización con Gemini: $e', error: e);
      return 'Otros';
    }
  }

  /// Genera un consejo de ahorro personalizado analizando gastos e ingresos recientes,
  /// metas de ahorro y deudas.
  Future<String> getPersonalizedTip(
    List<ExpenseEntity> expenses,
    List<IncomeEntity> incomes, {
    List<Goal>? goals,
    List<Debt>? debts,
  }) async {
    if (expenses.isEmpty &&
        incomes.isEmpty &&
        (goals == null || goals.isEmpty) &&
        (debts == null || debts.isEmpty)) {
      return 'Comienza a registrar tus movimientos, metas o deudas para darte consejos financieros personalizados.';
    }

    final String expensesSummary =
        expenses.isEmpty
            ? 'Sin gastos recientes.'
            : expenses
                .take(10)
                .map(
                  (e) =>
                      '- ${e.title}: Q${e.amount} (Categoría: ${e.category})',
                )
                .join('\n');

    final String incomesSummary =
        incomes.isEmpty
            ? 'Sin ingresos recientes.'
            : incomes
                .take(5)
                .map((i) => '- ${i.title}: Q${i.amount}')
                .join('\n');

    final String goalsSummary =
        (goals != null && goals.isNotEmpty)
            ? goals
                .map(
                  (g) =>
                      '- Meta: "${g.nombre}", Objetivo: Q${g.montoObjetivo}, Actual: Q${g.montoActual}, Fecha límite: ${g.fechaLimite.toIso8601String().split('T').first}',
                )
                .join('\n')
            : 'Sin metas de ahorro configuradas.';

    final String debtsSummary =
        (debts != null && debts.isNotEmpty)
            ? debts
                .map(
                  (d) =>
                      '- Deuda: "${d.name}", Saldo actual: Q${d.currentBalance}, Monto original: Q${d.originalAmount}, Tasa: ${d.interestRate}%, Próximo pago: ${d.nextPaymentDate.toIso8601String().split('T').first}',
                )
                .join('\n')
            : 'Sin deudas registradas.';

    final prompt = '''
Eres un asesor financiero personal amigable y experto. Analiza el siguiente resumen de movimientos recientes del usuario, sus metas de ahorro y sus deudas. Genera un único consejo de ahorro personalizado, práctico y motivador en español.
El consejo debe ser muy conciso (máximo 2 frases) y fácil de leer.

Ingresos recientes del usuario:
$incomesSummary

Gastos recientes del usuario:
$expensesSummary

Metas de ahorro del usuario:
$goalsSummary

Deudas del usuario:
$debtsSummary

Por favor, responde directamente con el consejo corto de 1 o 2 frases.
IMPORTANTE: Si detectas que el usuario tiene movimientos (ingresos o gastos) relacionados con un negocio, ventas o emprendimiento (por ejemplo, transacciones que mencionen 'ventas', 'venta', 'negocio', 'cliente', 'mercadería', etc.), debes reconocer y hacer mención de que realiza actividades comerciales. Ofrécele un consejo financiero estratégico para optimizar el flujo de caja de su negocio, reinvertir utilidades o separar sus finanzas personales de las comerciales.
Si el usuario tiene deudas con altas tasas de interés, prioriza sugerir atacarlas (ej. método avalancha o bola de nieve). Si tiene metas de ahorro rezagadas, aconséjale cómo ajustar sus gastos. No agregues saludos, introducciones ni explicaciones de tu análisis.
''';

    try {
      final responseText = await _client.generate(prompt);
      return responseText?.trim() ??
          'Considera registrar todos tus gastos diarios para identificar fugas de dinero invisibles.';
    } catch (e) {
      developer.log(
        'Error en consejos personalizados con Gemini: $e',
        error: e,
      );
      return 'Mantén un registro constante de tus gastos para ayudarte a controlar tu presupuesto mensual.';
    }
  }

  /// Extrae datos financieros estructurados del texto OCR de un documento
  /// (factura, recibo, estado de cuenta). Devuelve null si el texto está vacío.
  Future<ScannedFinancialDocument?> extractFinancialDataFromDocument(
    String ocrText,
  ) async {
    if (ocrText.trim().isEmpty) return null;

    final prompt = '''
Eres un extractor de datos financieros experto. Del siguiente texto OCR de un documento financiero guatemalteco (factura, recibo, estado de cuenta), extrae los datos relevantes.

Texto OCR:
$ocrText

Responde ÚNICAMENTE con JSON válido, sin texto adicional ni bloques de código:
{"amount": 125.50, "merchant": "Supermercado La Torre", "date": "2024-01-15", "category": "Alimentación", "description": "Compras supermercado"}

Categorías válidas: Alimentación, Transporte, Hogar, Entretenimiento, Compras, Salud, Créditos, Negocio, Otros
Si el documento tiene relación con ventas, clientes o inventario de un negocio, clasifícalo en la categoría "Negocio".
Si no puedes extraer un campo, usa null. El monto debe ser el total del documento.
''';

    try {
      final responseText = await _client.generate(prompt);
      if (responseText == null) return null;
      final clean = responseText
          .trim()
          .replaceAll(RegExp(r'^```.*\n?'), '')
          .replaceAll('```', '');
      final json = jsonDecode(clean) as Map<String, dynamic>;
      return ScannedFinancialDocument.fromJson(json);
    } catch (e) {
      developer.log(
        'Error extrayendo datos de documento con Gemini: $e',
        error: e,
      );
      return null;
    }
  }

  /// Predice el gasto de la próxima semana basándose en el historial reciente.
  Future<String> getSpendingPrediction(
    List<ExpenseEntity> expenses,
    List<IncomeEntity> incomes,
  ) async {
    if (expenses.isEmpty) {
      return 'Registra al menos una semana de gastos para activar las predicciones de gasto.';
    }

    final expensesSummary = expenses
        .take(20)
        .map(
          (e) =>
              '- ${e.title}: Q${e.amount.toStringAsFixed(0)} (${e.category}) — ${e.date.toIso8601String().split('T').first}',
        )
        .join('\n');

    final totalIncomes = incomes.fold<double>(0, (s, i) => s + i.amount);

    final prompt = '''
Eres un analista financiero predictivo. Basado en los siguientes gastos recientes del usuario guatemalteco, predice cuánto gastará la PRÓXIMA SEMANA.

Ingresos recientes totales: Q${totalIncomes.toStringAsFixed(0)}

Gastos recientes:
$expensesSummary

Responde en máximo 2 frases, en español.
Si detectas gastos o ingresos relacionados con ventas o con su negocio, tenlo en cuenta para estimar el flujo de caja operativo y hazle una breve mención sobre el comportamiento financiero de su negocio o emprendimiento.
Sé específico: menciona el monto estimado total y las categorías principales. No agregues saludos ni explicaciones.
''';

    try {
      final responseText = await _client.generate(prompt);
      return responseText?.trim() ??
          'No se pudo generar la predicción. Registra más transacciones para mejorar la precisión.';
    } catch (e) {
      developer.log('Error en predicción de gastos con Gemini: $e', error: e);
      return 'No se pudo generar la predicción en este momento.';
    }
  }

  /// Genera un reporte mensual completo con análisis de ingresos, gastos,
  /// patrones de comportamiento y recomendaciones accionables.
  Future<String> generateMonthlyReport({
    required List<ExpenseEntity> expenses,
    required List<IncomeEntity> incomes,
    required double totalIncome,
    required double totalExpenses,
    required String monthLabel,
  }) async {
    if (expenses.isEmpty && incomes.isEmpty) {
      return 'No hay transacciones registradas en $monthLabel para generar un reporte.';
    }

    final savings = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (savings / totalIncome * 100) : 0.0;

    final Map<String, double> categoryTotals = {};
    for (final e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }
    final topCategories = (categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => '- ${e.key}: Q${e.value.toStringAsFixed(2)}')
        .join('\n');

    String fmtDate(DateTime dt) => dt.toIso8601String().split('T').first;

    final incomeDetails = incomes.isEmpty
        ? 'Sin ingresos registrados.'
        : incomes
            .map(
              (i) =>
                  '- ${i.title}: Q${i.amount.toStringAsFixed(2)}'
                  ' | Fecha: ${fmtDate(i.date)}'
                  ' | Registrado: ${fmtDate(i.createdAt)}'
                  ' | Actualizado: ${fmtDate(i.updatedAt)}',
            )
            .join('\n');

    final expenseDetails = expenses.isEmpty
        ? 'Sin gastos registrados.'
        : expenses
            .map(
              (e) =>
                  '- ${e.title}: Q${e.amount.toStringAsFixed(2)}'
                  ' | Cat: ${e.category}'
                  ' | Fecha: ${fmtDate(e.date)}'
                  ' | Registrado: ${fmtDate(e.createdAt)}'
                  ' | Actualizado: ${fmtDate(e.updatedAt)}',
            )
            .join('\n');

    final prompt = '''
Eres un asesor financiero personal experto en finanzas para Guatemala. Genera un reporte mensual financiero detallado, profesional y motivador para el mes de $monthLabel.

DATOS FINANCIEROS:
- Ingresos totales: Q${totalIncome.toStringAsFixed(2)}
- Gastos totales: Q${totalExpenses.toStringAsFixed(2)}
- Balance neto: Q${savings.toStringAsFixed(2)}
- Tasa de ahorro: ${savingsRate.toStringAsFixed(1)}%

DETALLE DE INGRESOS (Fecha = fecha del movimiento, Registrado = cuándo se ingresó al sistema):
$incomeDetails

DETALLE DE GASTOS (Fecha = fecha del movimiento, Registrado = cuándo se ingresó al sistema):
$expenseDetails

TOP CATEGORÍAS DE GASTOS:
$topCategories

Genera el reporte con las siguientes secciones (usa emojis para hacerlo visual):

1. 📊 RESUMEN EJECUTIVO (2-3 frases sobre el mes)
2. 💰 ANÁLISIS DE INGRESOS (comportamiento de ingresos)
3. 💸 ANÁLISIS DE GASTOS (patrones y categorías principales)
4. 📈 BALANCE Y AHORRO (evaluación del ahorro del mes)
5. ⚠️ ALERTAS (si hay algo preocupante, máximo 2 puntos)
6. 🎯 RECOMENDACIONES (3 acciones concretas y prácticas para el próximo mes)

Sé específico con los montos en quetzales (Q). Usa un tono profesional pero amigable. Máximo 300 palabras en total.
''';

    try {
      final responseText = await _client.generate(prompt);
      return responseText?.trim() ??
          'No se pudo generar el reporte en este momento. Por favor intenta de nuevo.';
    } catch (e) {
      developer.log('Error generando reporte mensual con Gemini: $e', error: e);
      return 'Error al generar el reporte. Verifica tu conexión e intenta de nuevo.';
    }
  }

  /// Envía un mensaje al asistente financiero manteniendo el historial de conversación.
  /// [history]: lista de mensajes previos, cada uno con `role` ('user' | 'model') y `text`.
  Future<String> sendChatMessage(
    String userMessage,
    List<({String role, String text})> history,
  ) async {
    const systemContext =
        'Eres un asesor financiero personal experto, amigable y empático, '
        'especializado en finanzas personales para Guatemala. '
        'Ayudas a los usuarios a entender sus gastos, presupuestos, metas de ahorro y deudas. '
        'Usas quetzales (Q) como moneda y referencias locales de Guatemala cuando sea relevante. '
        'Responde siempre en español, de forma clara y concisa. '
        'No repitas los datos que el usuario ya conoce; ve directo al consejo o análisis.';

    final contents = <Content>[
      Content('user', [const TextPart(systemContext)]),
      Content('model', [
        const TextPart(
          'Entendido. Soy tu asesor financiero personal para Guatemala. ¿En qué te puedo ayudar hoy?',
        ),
      ]),
      ...history.map((m) => Content(m.role, [TextPart(m.text)])),
      Content('user', [TextPart(userMessage)]),
    ];

    try {
      final responseText = await _client.generateMultiTurn(contents);
      return responseText?.trim() ??
          'No pude procesar tu consulta. Por favor, intenta de nuevo.';
    } catch (e) {
      developer.log('Error en chat financiero con Gemini: $e', error: e);
      return 'Ocurrió un error al conectar con el asistente. Verifica tu conexión e intenta de nuevo.';
    }
  }

  /// Calcula el score de salud financiera (0–100) del usuario.
  Future<FinancialHealthScore> getFinancialHealthScore({
    required double totalIncomes,
    required double totalExpenses,
    required int activeGoals,
    required int activeDebts,
    required double goalsProgress,
    required double totalDebtBalance,
  }) async {
    if (totalIncomes == 0 && totalExpenses == 0) {
      return FinancialHealthScore.fallback();
    }

    final savingsRate =
        totalIncomes > 0
            ? ((totalIncomes - totalExpenses) / totalIncomes * 100).clamp(
              0,
              100,
            )
            : 0;
    final debtToIncome =
        totalIncomes > 0
            ? (totalDebtBalance / totalIncomes * 100).clamp(0, 300)
            : 0;

    final prompt = '''
Eres un asesor financiero certificado. Evalúa la salud financiera de este usuario guatemalteco y asigna un puntaje de 0 a 100.

Datos financieros:
- Ingresos totales del período: Q${totalIncomes.toStringAsFixed(0)}
- Gastos totales del período: Q${totalExpenses.toStringAsFixed(0)}
- Tasa de ahorro: ${savingsRate.toStringAsFixed(1)}%
- Metas de ahorro activas: $activeGoals
- Progreso promedio de metas: ${goalsProgress.toStringAsFixed(0)}%
- Deudas activas: $activeDebts
- Saldo total de deudas: Q${totalDebtBalance.toStringAsFixed(0)}
- Relación deuda/ingreso: ${debtToIncome.toStringAsFixed(1)}%

Escala de grades: A (90–100), B (75–89), C (60–74), D (45–59), F (0–44)

Responde ÚNICAMENTE con JSON válido, sin texto adicional:
{"score": 72, "grade": "B", "summary": "Tu balance es positivo y tienes metas activas, pero tus deudas representan el 45% de tu ingreso. Enfócate en reducirlas."}

El summary debe ser 1 frase concreta y motivadora en español. Si el usuario cuenta con ingresos o egresos por concepto de ventas o negocio, adapta tu frase/resumen para valorar positivamente su emprendimiento y dale un tip rápido para su control financiero comercial.
''';

    try {
      final responseText = await _client.generate(prompt);
      if (responseText == null) return FinancialHealthScore.fallback();
      final clean = responseText
          .trim()
          .replaceAll(RegExp(r'^```.*\n?'), '')
          .replaceAll('```', '');
      final json = jsonDecode(clean) as Map<String, dynamic>;
      return FinancialHealthScore.fromJson(json);
    } catch (e) {
      developer.log(
        'Error en score de salud financiera con Gemini: $e',
        error: e,
      );
      return FinancialHealthScore.fallback();
    }
  }
}
