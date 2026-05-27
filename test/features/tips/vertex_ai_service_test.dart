import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_finance/core/domain/entities/sync_status.dart';
import 'package:personal_finance/core/services/vertex_ai_service.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';

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
  });
}
