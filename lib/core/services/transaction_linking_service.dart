import 'package:flutter/foundation.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart';

class TransactionLinkingService {
  TransactionLinkingService({
    required TransactionBackendRepository transactionRepo,
    required GoalRepository goalRepo,
    required DebtRepository debtRepo,
  })  : _transactionRepo = transactionRepo,
        _goalRepo = goalRepo,
        _debtRepo = debtRepo;

  final TransactionBackendRepository _transactionRepo;
  final GoalRepository _goalRepo;
  final DebtRepository _debtRepo;

  /// Removes Spanish diacritics for accent-insensitive matching.
  String _normalize(String s) => s
      .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
      .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ü', 'u')
      .replaceAll('ñ', 'n').replaceAll('Á', 'A').replaceAll('É', 'E')
      .replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
      .replaceAll('Ü', 'U').replaceAll('Ñ', 'N');

  /// Returns 3+ character keywords from a name, lowercased.
  List<String> _keywords(String name) => _normalize(name)
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
      .split(RegExp(r'\s+'))
      .where((w) => w.length >= 3)
      .toList();

  /// True if the description contains any keyword from the list.
  bool _matches(String description, List<String> keywords) {
    final lower = _normalize(description).toLowerCase();
    return keywords.any(lower.contains);
  }

  /// Sums all existing transactions of [tipo] whose description matches [name].
  /// Returns 0.0 on any error or no match.
  Future<double> sumMatchingTransactions(String name, String tipo) async {
    final keywords = _keywords(name);
    if (keywords.isEmpty) return 0.0;

    final result = await _transactionRepo.list(tipo: tipo);
    return result.fold(
      (_) => 0.0,
      (transactions) => transactions
          .where((t) => _matches(t.descripcion, keywords))
          .fold<double>(0.0, (sum, t) => sum + (double.tryParse(t.monto) ?? 0.0)),
    );
  }

  /// Called after every new transaction is saved.
  /// Updates matching goals (income) or debts (expense) silently.
  Future<void> processTransaction(TransactionBackend transaction) async {
    try {
      final amount = double.tryParse(transaction.monto) ?? 0.0;
      if (amount <= 0) return;

      final keywords = _keywords(transaction.descripcion);
      if (keywords.isEmpty) return;

      if (transaction.tipo == 'ingreso') {
        await _updateMatchingGoals(transaction.descripcion, amount);
      } else if (transaction.tipo == 'gasto') {
        await _updateMatchingDebts(transaction.descripcion, amount);
      }
    } catch (e) {
      debugPrint('[TransactionLinkingService] processTransaction error: $e');
    }
  }

  Future<void> _updateMatchingGoals(
    String transactionDescription,
    double amount,
  ) async {
    final result = await _goalRepo.getGoals();
    final goals = result.fold((_) => <Goal>[], (g) => g);
    for (final goal in goals) {
      if (goal.actualAsDouble >= goal.objetivoAsDouble) continue;
      final goalKeywords = _keywords(goal.nombre);
      if (!_matches(transactionDescription, goalKeywords)) continue;
      final newAmount = goal.actualAsDouble + amount;
      await _goalRepo.updateGoal(
        goal.copyWith(montoActual: newAmount.toStringAsFixed(2)),
      );
    }
  }

  Future<void> _updateMatchingDebts(
    String transactionDescription,
    double amount,
  ) async {
    final result = await _debtRepo.getDebts();
    final debts = result.fold((_) => <Debt>[], (d) => d);
    for (final debt in debts) {
      if (debt.currentBalance <= 0) continue;
      final debtKeywords = _keywords(debt.name);
      if (!_matches(transactionDescription, debtKeywords)) continue;
      final newBalance =
          (debt.currentBalance - amount).clamp(0.0, double.infinity);
      await _debtRepo.updateDebt(debt.copyWith(currentBalance: newBalance));
    }
  }
}
