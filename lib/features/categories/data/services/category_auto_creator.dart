import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/categories/domain/entities/category.dart';
import 'package:personal_finance/features/categories/domain/repositories/category_repository.dart';
import 'package:personal_finance/features/quick_finance/domain/services/transaction_categorizer.dart';

/// Crea en "Categorías" las que la app detecta sola en los movimientos, para
/// que el usuario las vea y pueda asignarlas a sus presupuestos.
///
/// El documento usa el mismo identificador que el movimiento (`comida`), así
/// presupuestos y movimientos coinciden sin traducciones. Si el usuario ya
/// tenía una categoría con ese nombre ("Comida"), no se duplica.
class CategoryAutoCreator {
  CategoryAutoCreator(this._repository, {required String Function() deviceId})
    : _deviceId = deviceId;

  final CategoryRepository _repository;
  final String Function() _deviceId;

  /// Identificadores ya verificados en esta sesión (evita leer Firestore en
  /// cada gasto).
  final Set<String> _known = <String>{};

  Future<void> ensure(String categoryId, TransactionType type) async {
    final slug = TransactionCategorizer.normalize(categoryId);
    if (slug == null || _known.contains(slug)) return;

    final existing = await _repository.getCategories();
    final List<Category>? categories = existing.fold((_) => null, (c) => c);
    if (categories == null)
      return; // Sin red: se reintenta en el próximo gasto.

    final bool exists = categories.any(
      (c) =>
          c.deletedAt == null &&
          (c.id == slug || TransactionCategorizer.normalize(c.nombre) == slug),
    );
    if (!exists) {
      final now = DateTime.now();
      final created = await _repository.createCategory(
        Category(
          id: slug,
          createdAt: now,
          updatedAt: now,
          deviceId: _deviceId(),
          version: 1,
          nombre: TransactionCategorizer.displayName(slug),
          tipo: type == TransactionType.income ? 'ingreso' : 'egreso',
        ),
      );
      if (created.isLeft()) return;
    }
    _known.add(slug);
  }
}
