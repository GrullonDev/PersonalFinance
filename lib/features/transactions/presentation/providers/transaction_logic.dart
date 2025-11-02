import 'package:flutter/material.dart';

import 'package:personal_finance/features/transactions/domain/entities/transaction_model.dart';

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
      // TODO: Implement actual saving logic with your backend service
      await Future<void>.delayed(const Duration(seconds: 1)); // Simulated delay
      _currentTransaction = null;
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
