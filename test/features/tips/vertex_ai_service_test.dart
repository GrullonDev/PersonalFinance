import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_finance/core/domain/entities/sync_status.dart';
import 'package:personal_finance/core/services/vertex_ai_service.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';

class MockGeminiClient extends Mock implements GeminiClient {}

void main() {
  late MockGeminiClient mockClient;
  late VertexAiService vertexAiService;

  setUp(() {
    mockClient = MockGeminiClient();
    vertexAiService = VertexAiService(client: mockClient);
  });

  group('VertexAiService Tests with MockGeminiClient', () {
    test('getCategoryForExpense returns correct category on successful prediction', () async {
      when(() => mockClient.generate(any())).thenAnswer((_) async => 'Alimentación');

      final category = await vertexAiService.getCategoryForExpense('Comida en el restaurante');
      expect(category, 'Alimentación');
    });

    test('getCategoryForExpense returns Otros on exception', () async {
      when(() => mockClient.generate(any())).thenThrow(Exception('API Error'));

      final category = await vertexAiService.getCategoryForExpense('Algo aleatorio');
      expect(category, 'Otros');
    });

    test('getPersonalizedTip returns a tip on successful prediction', () async {
      when(() => mockClient.generate(any())).thenAnswer((_) async => 'Ahorra comiendo en casa.');

      final expenses = [
        ExpenseEntity(
          id: '1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deviceId: 'dev',
          version: 1,
          syncStatus: SyncStatus.synchronized,
          title: 'Sushi',
          amount: 50.0,
          date: DateTime.now(),
          category: 'Alimentación',
        ),
      ];

      final tip = await vertexAiService.getPersonalizedTip(expenses, []);
      expect(tip, 'Ahorra comiendo en casa.');
    });

    test('getPersonalizedTip returns default message when transactions are empty', () async {
      final tip = await vertexAiService.getPersonalizedTip([], []);
      expect(tip.contains('Comienza a registrar'), true);
    });

    test('getPersonalizedTip includes goals and debts in prompt', () async {
      when(() => mockClient.generate(any())).thenAnswer((_) async => 'Enfócate en tu meta Viaje y paga tu tarjeta.');

      final goals = [
        Goal(
          nombre: 'Viaje',
          montoObjetivo: '2000',
          montoActual: '500',
          fechaLimite: DateTime.now(),
        ),
      ];

      final debts = [
        Debt(
          id: 'd1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deviceId: 'dev',
          version: 1,
          name: 'Tarjeta de Crédito',
          currentBalance: 1000.0,
          originalAmount: 1000.0,
          interestRate: 15.0,
          nextPaymentDate: DateTime.now(),
          minimumPayment: 50.0,
        ),
      ];

      final tip = await vertexAiService.getPersonalizedTip([], [], goals: goals, debts: debts);
      expect(tip, 'Enfócate en tu meta Viaje y paga tu tarjeta.');
      
      final captured = verify(() => mockClient.generate(captureAny())).captured;
      expect(captured.length, 1);
      final promptText = captured.first as String;
      expect(promptText.contains('Viaje'), true);
      expect(promptText.contains('Tarjeta de Crédito'), true);
    });
  });
}
