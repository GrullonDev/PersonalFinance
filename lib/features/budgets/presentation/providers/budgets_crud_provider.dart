import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';
import 'package:personal_finance/features/budgets/domain/repositories/budget_repository.dart';

class BudgetsCrudProvider extends ChangeNotifier {
  BudgetsCrudProvider({required BudgetRepository repository})
    : _repository = repository;

  final BudgetRepository _repository;
  final List<Budget> _budgets = <Budget>[];
  bool _loading = false;
  String? _error;

  List<Budget> get budgets => List<Budget>.unmodifiable(_budgets);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _setLoading(true);
    final Either<Failure, List<Budget>> res = await _repository.getBudgets();
    res.fold((Failure l) => _error = l.message, (List<Budget> r) {
      _error = null;
      _budgets
        ..clear()
        ..addAll(r);
    });
    _setLoading(false);
  }

  Future<bool> create(Budget budget) async {
    _setLoading(true);
    final Either<Failure, Budget> res = await _repository.createBudget(budget);
    final bool ok = res.isRight();
    res.fold((Failure l) => _error = l.message, (Budget r) {
      _error = null;
      _budgets.add(r);
    });
    _setLoading(false);
    return ok;
  }

  Future<bool> update(Budget budget) async {
    _setLoading(true);
    final Either<Failure, Budget> res = await _repository.updateBudget(budget);
    final bool ok = res.isRight();
    res.fold((Failure l) => _error = l.message, (Budget r) {
      _error = null;
      final int i = _budgets.indexWhere((Budget b) => b.id == r.id);
      if (i != -1) _budgets[i] = r;
    });
    _setLoading(false);
    return ok;
  }

  Future<bool> remove(Budget budget) async {
    if (budget.id == null) return false;
    _setLoading(true);
    final Either<Failure, void> res = await _repository.deleteBudget(
      budget.id!,
    );
    final bool ok = res.isRight();
    res.fold((Failure l) => _error = l.message, (_) {
      _error = null;
      _budgets.removeWhere((Budget b) => b.id == budget.id);
    });
    _setLoading(false);
    return ok;
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
