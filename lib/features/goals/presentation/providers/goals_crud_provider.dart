import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';

class GoalsCrudProvider extends ChangeNotifier {
  GoalsCrudProvider({required GoalRepository repository})
    : _repository = repository;

  final GoalRepository _repository;
  final List<Goal> _goals = <Goal>[];
  bool _loading = false;
  String? _error;

  List<Goal> get goals => List<Goal>.unmodifiable(_goals);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _setLoading(true);
    final Either<Failure, List<Goal>> res = await _repository.getGoals();
    res.fold((Failure l) => _error = l.message, (List<Goal> r) {
      _error = null;
      _goals
        ..clear()
        ..addAll(r);
    });
    _setLoading(false);
  }

  Future<bool> create(Goal goal) async {
    _setLoading(true);
    final Either<Failure, Goal> res = await _repository.createGoal(goal);
    final bool ok = res.isRight();
    res.fold((Failure l) => _error = l.message, (Goal r) {
      _error = null;
      _goals.add(r);
    });
    _setLoading(false);
    return ok;
  }

  Future<bool> update(Goal goal) async {
    _setLoading(true);
    final Either<Failure, Goal> res = await _repository.updateGoal(goal);
    final bool ok = res.isRight();
    res.fold((Failure l) => _error = l.message, (Goal r) {
      _error = null;
      final int i = _goals.indexWhere((Goal g) => g.id == r.id);
      if (i != -1) _goals[i] = r;
    });
    _setLoading(false);
    return ok;
  }

  Future<bool> remove(Goal goal) async {
    if (goal.id == null) return false;
    _setLoading(true);
    final Either<Failure, void> res = await _repository.deleteGoal(goal.id!);
    final bool ok = res.isRight();
    res.fold((Failure l) => _error = l.message, (_) {
      _error = null;
      _goals.removeWhere((Goal g) => g.id == goal.id);
    });
    _setLoading(false);
    return ok;
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
