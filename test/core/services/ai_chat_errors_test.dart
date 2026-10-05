import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_finance/core/services/vertex_ai_service.dart';

class _Client extends Mock implements GeminiClient {}

void main() {
  setUpAll(() => registerFallbackValue(<Content>[]));

  test('clasifica los errores de la IA', () {
    expect(
      AiErrorReason.of(Exception('SocketException: Failed host lookup')),
      AiErrorReason.network,
    );
    expect(
      AiErrorReason.of(Exception('Firebase App Check token is invalid')),
      AiErrorReason.appCheck,
    );
    expect(
      AiErrorReason.of(Exception('models/gemini-x is not found for API')),
      AiErrorReason.model,
    );
    expect(
      AiErrorReason.of(Exception('RESOURCE_EXHAUSTED: quota exceeded')),
      AiErrorReason.quota,
    );
    expect(
      AiErrorReason.of(
        Exception('PERMISSION_DENIED: API has not been used in project'),
      ),
      AiErrorReason.notEnabled,
    );
  });

  test('el chat marca el error y explica el motivo', () async {
    final client = _Client();
    when(
      () => client.generateMultiTurn(any()),
    ).thenThrow(Exception('models/gemini-2.5-flash is not found'));

    final reply = await VertexAiService(client: client).chat('hola', const []);

    expect(reply.isError, isTrue);
    expect(reply.text, contains(AiErrorReason.model.message));
  });

  test('una respuesta válida no es error', () async {
    final client = _Client();
    when(
      () => client.generateMultiTurn(any()),
    ).thenAnswer((_) async => '- Ahorra **Q100**');

    final reply = await VertexAiService(client: client).chat('hola', const []);

    expect(reply.isError, isFalse);
    expect(reply.text, '- Ahorra **Q100**');
  });
}
