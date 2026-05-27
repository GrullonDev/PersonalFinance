import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
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
      : _client = client ??
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
        'Otros'
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

  /// Genera un consejo de ahorro personalizado analizando gastos e ingresos recientes
  Future<String> getPersonalizedTip(
    List<ExpenseEntity> expenses,
    List<IncomeEntity> incomes,
  ) async {
    if (expenses.isEmpty && incomes.isEmpty) {
      return 'Comienza a registrar tus gastos e ingresos para darte consejos financieros personalizados.';
    }

    final String expensesSummary = expenses
        .take(10)
        .map((e) => '- ${e.title}: Q${e.amount} (Categoría: ${e.category})')
        .join('\n');

    final String incomesSummary = incomes
        .take(5)
        .map((i) => '- ${i.title}: Q${i.amount}')
        .join('\n');

    final prompt = '''
Eres un asesor financiero personal amigable y experto. Analiza el siguiente resumen de movimientos recientes del usuario y genera un único consejo de ahorro personalizado, práctico y motivador en español.
El consejo debe ser muy conciso (máximo 2 frases) y fácil de leer.

Ingresos recientes del usuario:
$incomesSummary

Gastos recientes del usuario:
$expensesSummary

Por favor, responde directamente con el consejo corto de 1 o 2 frases. No agregues saludos, introducciones ni explicaciones de tu análisis.
''';

    try {
      final responseText = await _client.generate(prompt);
      return responseText?.trim() ??
          'Considera registrar todos tus gastos diarios para identificar fugas de dinero invisibles.';
    } catch (e) {
      developer.log('Error en consejos personalizados con Gemini: $e', error: e);
      return 'Mantén un registro constante de tus gastos para ayudarte a controlar tu presupuesto mensual.';
    }
  }
}
