import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:personal_finance/core/services/device_service.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_model.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart';

class TransactionLogic extends ChangeNotifier {
  TransactionModel? _currentTransaction;
  bool _isLoading = false;

  TransactionModel? get currentTransaction => _currentTransaction;
  bool get isLoading => _isLoading;

  void updateTransactionType(TransactionType type) {
    _currentTransaction = (_currentTransaction ??
            TransactionModel(
              type: type,
              amount: 0,
              category: '',
              date: DateTime.now(),
            ))
        .copyWith(type: type);
    notifyListeners();
  }

  void updateAmount(double amount) {
    _currentTransaction = (_currentTransaction ??
            TransactionModel(
              type: TransactionType.expense,
              amount: amount,
              category: '',
              date: DateTime.now(),
            ))
        .copyWith(amount: amount);
    notifyListeners();
  }

  void updateCategory(String category) {
    _currentTransaction = (_currentTransaction ??
            TransactionModel(
              type: TransactionType.expense,
              amount: 0,
              category: category,
              date: DateTime.now(),
            ))
        .copyWith(category: category);
    notifyListeners();
  }

  void updateDate(DateTime date) {
    _currentTransaction = (_currentTransaction ??
            TransactionModel(
              type: TransactionType.expense,
              amount: 0,
              category: '',
              date: date,
            ))
        .copyWith(date: date);
    notifyListeners();
  }

  void updateDescription(String description) {
    _currentTransaction = (_currentTransaction ??
            TransactionModel(
              type: TransactionType.expense,
              amount: 0,
              category: '',
              date: DateTime.now(),
            ))
        .copyWith(description: description);
    notifyListeners();
  }

  void updateIsRecurring({required bool isRecurring}) {
    _currentTransaction = (_currentTransaction ??
            TransactionModel(
              type: TransactionType.expense,
              amount: 0,
              category: '',
              date: DateTime.now(),
            ))
        .copyWith(isRecurring: isRecurring);
    notifyListeners();
  }

  Future<void> saveTransaction() async {
    if (_currentTransaction == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      final String deviceId = GetIt.instance<DeviceService>().deviceId;
      final DateTime now = DateTime.now();
      final TransactionModel tx = _currentTransaction!;

      final TransactionBackend entity = TransactionBackend(
        id: now.millisecondsSinceEpoch.toString(),
        tipo: tx.type == TransactionType.expense ? 'gasto' : 'ingreso',
        monto: tx.amount.toString(),
        descripcion: tx.description ?? '',
        fecha: tx.date,
        categoriaId: tx.category,
        esRecurrente: tx.isRecurring,
        createdAt: now,
        updatedAt: now,
        deviceId: deviceId,
        version: 1,
        profileType: uid,
      );

      final repo = GetIt.instance<TransactionBackendRepository>();
      final result = await repo.create(entity);
      result.fold((failure) => throw Exception(failure.message), (_) => null);

      _currentTransaction = null;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetTransaction() {
    _currentTransaction = null;
    notifyListeners();
  }
}
