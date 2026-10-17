import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/categories/data/services/category_auto_creator.dart';
import 'package:personal_finance/features/categories/domain/entities/category.dart';
import 'package:personal_finance/features/categories/domain/repositories/category_repository.dart';

class _MockRepo extends Mock implements CategoryRepository {}

Category _cat(String id, String nombre) => Category(
  id: id,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  deviceId: 'd',
  version: 1,
  nombre: nombre,
  tipo: 'egreso',
);

void main() {
  late _MockRepo repo;
  late CategoryAutoCreator creator;

  setUpAll(() => registerFallbackValue(_cat('x', 'X')));

  setUp(() {
    repo = _MockRepo();
    creator = CategoryAutoCreator(repo, deviceId: () => 'device');
    when(() => repo.createCategory(any())).thenAnswer(
      (inv) async => Right(inv.positionalArguments.first as Category),
    );
  });

  test('crea la categoría detectada si no existe', () async {
    when(() => repo.getCategories()).thenAnswer((_) async => const Right([]));

    await creator.ensure('comida', TransactionType.expense);

    final created =
        verify(() => repo.createCategory(captureAny())).captured.single
            as Category;
    expect(created.id, 'comida');
    expect(created.nombre, 'Comida');
    expect(created.tipo, 'egreso');
  });

  test('no duplica si el usuario ya tiene una con ese nombre', () async {
    when(
      () => repo.getCategories(),
    ).thenAnswer((_) async => Right([_cat('abc123', 'Comida')]));

    await creator.ensure('comida', TransactionType.expense);

    verifyNever(() => repo.createCategory(any()));
  });

  test('sólo consulta una vez por categoría en la sesión', () async {
    when(() => repo.getCategories()).thenAnswer((_) async => const Right([]));

    await creator.ensure('transporte', TransactionType.expense);
    await creator.ensure('transporte', TransactionType.expense);

    verify(() => repo.getCategories()).called(1);
  });

  test('sin red no crea nada y reintenta después', () async {
    when(
      () => repo.getCategories(),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'offline')));

    await creator.ensure('salud', TransactionType.expense);
    await creator.ensure('salud', TransactionType.expense);

    verifyNever(() => repo.createCategory(any()));
    verify(() => repo.getCategories()).called(2);
  });
}
