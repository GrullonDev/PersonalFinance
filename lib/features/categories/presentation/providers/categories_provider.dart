import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/categories/domain/entities/category.dart';
import 'package:personal_finance/features/categories/domain/repositories/category_repository.dart';

class CategoriesProvider extends ChangeNotifier {
  CategoriesProvider({required CategoryRepository repository})
    : _repository = repository;

  final CategoryRepository _repository;

  final List<Category> _categories = <Category>[];
  bool _loading = false;
  String? _error;

  List<Category> get categories => List<Category>.unmodifiable(_categories);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _setLoading(true);
    final Either<Failure, List<Category>> result =
        await _repository.getCategories();
    result.fold((Failure l) => _error = l.message, (List<Category> r) {
      _error = null;
      _categories
        ..clear()
        ..addAll(r);
    });
    _setLoading(false);
  }

  Future<bool> addCategory(String nombre, String tipo) async {
    _setLoading(true);
    final Either<Failure, Category> result = await _repository.createCategory(
      Category(nombre: nombre, tipo: tipo),
    );
    final bool ok = result.isRight();
    result.fold((Failure l) => _error = l.message, (Category r) {
      _error = null;
      _categories.add(r);
    });
    _setLoading(false);
    return ok;
  }

  Future<bool> editCategory(
    Category category,
    String nombre,
    String tipo,
  ) async {
    _setLoading(true);
    final Either<Failure, Category> result = await _repository.updateCategory(
      category.copyWith(nombre: nombre, tipo: tipo),
    );
    final bool ok = result.isRight();
    result.fold((Failure l) => _error = l.message, (Category r) {
      _error = null;
      final int idx = _categories.indexWhere((Category c) => c.id == r.id);
      if (idx != -1) {
        _categories[idx] = r;
      }
    });
    _setLoading(false);
    return ok;
  }

  Future<bool> removeCategory(Category category) async {
    _setLoading(true);
    final Either<Failure, void> result = await _repository.deleteCategory(
      category.id!,
    );
    final bool ok = result.isRight();
    result.fold((Failure l) => _error = l.message, (_) {
      _error = null;
      _categories.removeWhere((Category c) => c.id == category.id);
    });
    _setLoading(false);
    return ok;
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
