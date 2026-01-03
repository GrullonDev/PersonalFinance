import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart';

class TransactionsCrudProvider extends ChangeNotifier {
  TransactionsCrudProvider({required TransactionBackendRepository repository})
    : _repository = repository;

  final TransactionBackendRepository _repository;
  final List<TransactionBackend> _items = <TransactionBackend>[];
  bool _loading = false;
  String? _error;

  // Filtros
  DateTime? _desde;
  DateTime? _hasta;
  String? _categoriaId;
  String? _tipo; // 'ingreso' | 'gasto'

  List<TransactionBackend> get items =>
      List<TransactionBackend>.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;

  DateTime? get fechaDesde => _desde;
  DateTime? get fechaHasta => _hasta;
  String? get categoriaId => _categoriaId;
  String? get tipo => _tipo;

  void setFilters({
    DateTime? desde,
    DateTime? hasta,
    String? categoriaId,
    String? tipo,
  }) {
    _desde = desde;
    _hasta = hasta;
    _categoriaId = categoriaId;
    _tipo = tipo;
    notifyListeners();
  }

  Future<void> load() async => _loadInternal();

  Future<void> _loadInternal() async {
    _setLoading(true);
    final Either<Failure, List<TransactionBackend>> res = await _repository
        .list(
          fechaDesde: _desde,
          fechaHasta: _hasta,
          categoriaId: _categoriaId,
          tipo: _tipo,
        );
    res.fold((Failure l) => _error = l.message, (List<TransactionBackend> r) {
      _error = null;
      _items
        ..clear()
        ..addAll(r);
    });
    _setLoading(false);
  }

  Future<bool> create(TransactionBackend tx) async {
    _setLoading(true);
    final Either<Failure, TransactionBackend> res = await _repository.create(
      tx,
    );
    final bool ok = res.isRight();
    res.fold((Failure l) => _error = l.message, (TransactionBackend r) {
      _error = null;
      _items.insert(0, r);
    });
    _setLoading(false);
    return ok;
  }

  Future<bool> update(TransactionBackend tx) async {
    _setLoading(true);
    final Either<Failure, TransactionBackend> res = await _repository.update(
      tx,
    );
    final bool ok = res.isRight();
    res.fold((Failure l) => _error = l.message, (TransactionBackend r) {
      _error = null;
      final int i = _items.indexWhere((TransactionBackend e) => e.id == r.id);
      if (i != -1) _items[i] = r;
    });
    _setLoading(false);
    return ok;
  }

  Future<bool> remove(TransactionBackend tx) async {
    if (tx.id == null) return false;
    _setLoading(true);
    final Either<Failure, void> res = await _repository.delete(tx.id!);
    final bool ok = res.isRight();
    res.fold((Failure l) => _error = l.message, (_) {
      _error = null;
      _items.removeWhere((TransactionBackend e) => e.id == tx.id);
    });
    _setLoading(false);
    return ok;
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
