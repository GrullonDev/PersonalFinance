import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:personal_finance/core/services/device_service.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart';
import 'package:personal_finance/core/services/transaction_linking_service.dart';

class TransactionType {
  static const String expense = 'expense';
  static const String income = 'income';
}

class AddTransactionLogic extends ChangeNotifier {
  void clearError() => _clearError();
  bool _loading = false;
  String? _error;

  // Getters
  bool get isLoading => _loading;
  String? get error => _error;

  // Private methods
  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() => _setError(null);

  // Public methods
  Future<void> addTransaction(Map<String, dynamic> data, String type) async {
    _setLoading(true);
    _clearError();

    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      final String deviceId = GetIt.instance<DeviceService>().deviceId;
      final DateTime now = DateTime.now();

      final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final String category = (data['category'] as String?) ?? '';
      final DateTime fecha =
          data['date'] is DateTime ? data['date'] as DateTime : DateTime.now();
      final String descripcion = (data['description'] as String?) ?? '';
      final bool esRecurrente = (data['isRecurring'] as bool?) ?? false;

      final TransactionBackend entity = TransactionBackend(
        id: now.millisecondsSinceEpoch.toString(),
        tipo: type == TransactionType.expense ? 'gasto' : 'ingreso',
        monto: amount.toString(),
        descripcion: descripcion,
        fecha: fecha,
        categoriaId: category,
        esRecurrente: esRecurrente,
        createdAt: now,
        updatedAt: now,
        deviceId: deviceId,
        version: 1,
        profileType: uid,
      );

      final repo = GetIt.instance<TransactionBackendRepository>();
      final result = await repo.create(entity);
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          // Non-blocking: link transaction to matching goals/debts
          GetIt.instance<TransactionLinkingService>()
              .processTransaction(entity)
              .ignore();
        },
      );

      notifyListeners();
    } catch (e) {
      _setError(
        'Error al agregar ${type == TransactionType.expense ? 'gasto' : 'ingreso'}: $e',
      );
    } finally {
      _setLoading(false);
    }
  }
}
