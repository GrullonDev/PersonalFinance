import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/services/transaction_categorizer.dart';

TransactionEntity _tx(String note, String? category) => TransactionEntity(
  id: note,
  userId: 'u',
  type: TransactionType.expense,
  amount: 10,
  note: note,
  categoryId: category,
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
  syncStatus: SyncStatus.synced,
  version: 1,
  deviceId: 'd',
);

void main() {
  final categorizer = TransactionCategorizer();

  String? local(String note, {List<TransactionEntity> history = const []}) =>
      categorizer.categorizeLocally(
        note: note,
        type: TransactionType.expense,
        history: history,
      );

  test('detecta la categoría sólo con el nombre del lugar', () {
    expect(local('Starbucks'), 'comida');
    expect(local('Uber'), 'transporte');
    expect(local('Paiz'), 'supermercado');
    expect(local('Netflix'), 'suscripciones');
    expect(local('Farmacia Galeno'), 'salud');
    expect(local('almuerzo con amigos'), 'comida');
    expect(local('pago de renta'), 'hogar');
  });

  test('reutiliza la categoría que el usuario ya usó para ese lugar', () {
    final history = [_tx('Tienda Don Pepe', 'snacks')];
    expect(local('tienda don pepe', history: history), 'snacks');
  });

  test('sin descripción o desconocido no inventa categoría', () {
    expect(local('Sin descripción'), isNull);
    expect(local('XYZ 123'), isNull);
    expect(local(''), isNull);
  });

  test('ingresos sin pista caen en "ingresos"', () {
    expect(
      categorizer.categorizeLocally(
        note: 'Pago de planilla',
        type: TransactionType.income,
      ),
      'salario',
    );
    expect(
      categorizer.categorizeLocally(note: 'Juan', type: TransactionType.income),
      'ingresos',
    );
  });

  test('normaliza los nombres de la IA', () {
    expect(TransactionCategorizer.normalize('Alimentación'), 'comida');
    expect(TransactionCategorizer.normalize(' Transporte '), 'transporte');
    expect(TransactionCategorizer.normalize('Créditos'), 'creditos');
    expect(TransactionCategorizer.normalize('#Hogar'), 'hogar');
    expect(TransactionCategorizer.normalize('Otros'), isNull);
    expect(TransactionCategorizer.displayName('educacion'), 'Educación');
    expect(TransactionCategorizer.displayName('mascotas'), 'Mascotas');
  });

  test('usa la IA cuando las reglas locales no saben', () async {
    final withAi = TransactionCategorizer(ai: (_) async => 'Entretenimiento');
    expect(await withAi.categorizeWithAi('Fiesta de Ana'), 'entretenimiento');

    final failing = TransactionCategorizer(ai: (_) async => throw Exception());
    expect(await failing.categorizeWithAi('Fiesta de Ana'), isNull);
  });
}
