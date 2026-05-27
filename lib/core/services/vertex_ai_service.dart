import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'dart:developer' as developer;

/// Interfaz para abstraer el cliente de Gemini y facilitar pruebas unitarias.
abstract class GeminiClient {
  Future<String?> generate(String prompt);
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
}

class VertexAiService {
  final GeminiClient _client;

  VertexAiService({GeminiClient? client})
    : _client =
          client ??
          FirebaseGeminiClient(
            FirebaseVertexAI.instance.generativeModel(
              model: 'gemini-1.5-flash',
            ),
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
    if (expenses.isEmpty && incomes.isEmpty && (goals == null || goals.isEmpty) && (debts == null || debts.isEmpty)) {
      return 'Comienza a registrar tus movimientos, metas o deudas para darte consejos financieros personalizados.';
    }

    final String expensesSummary = expenses.isEmpty
        ? 'Sin gastos recientes.'
        : expenses
            .take(10)
            .map((e) => '- ${e.title}: Q${e.amount} (Categoría: ${e.category})')
            .join('\n');

    final String incomesSummary = incomes.isEmpty
        ? 'Sin ingresos recientes.'
        : incomes
            .take(5)
            .map((i) => '- ${i.title}: Q${i.amount}')
            .join('\n');

    final String goalsSummary = (goals != null && goals.isNotEmpty)
        ? goals
            .map((g) => '- Meta: "${g.nombre}", Objetivo: Q${g.montoObjetivo}, Actual: Q${g.montoActual}, Fecha límite: ${g.fechaLimite.toIso8601String().split('T').first}')
            .join('\n')
        : 'Sin metas de ahorro configuradas.';

    final String debtsSummary = (debts != null && debts.isNotEmpty)
        ? debts
            .map((d) => '- Deuda: "${d.name}", Saldo actual: Q${d.currentBalance}, Monto original: Q${d.originalAmount}, Tasa: ${d.interestRate}%, Próximo pago: ${d.nextPaymentDate.toIso8601String().split('T').first}')
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

Por favor, responde directamente con el consejo corto de 1 o 2 frases. Si el usuario tiene deudas con altas tasas de interés, prioriza sugerir atacarlas (ej. método avalancha o bola de nieve). Si tiene metas de ahorro rezagadas, aconséjale cómo ajustar sus gastos. No agregues saludos, introducciones ni explicaciones de tu análisis.
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
}
