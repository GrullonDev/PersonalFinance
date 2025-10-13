import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:personal_finance/features/dashboard/widgets/add_expense_modal.dart';
import 'package:personal_finance/features/dashboard/widgets/add_income_modal.dart';
import 'package:personal_finance/features/transactions/logic/add_transaction_logic.dart';

class AddTransactionView extends StatelessWidget {
  const AddTransactionView({super.key});

  void _showExpenseModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const AddExpenseModal(),
    );
  }

  void _showIncomeModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const AddIncomeModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AddTransactionLogic logic = context.watch<AddTransactionLogic>();

    if (logic.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (logic.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              logic.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => logic.clearError(),
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton.icon(
            onPressed: () => _showExpenseModal(context),
            icon: const Icon(Icons.arrow_downward),
            label: const Text('Agregar Gasto'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showIncomeModal(context),
            icon: const Icon(Icons.arrow_upward),
            label: const Text('Agregar Ingreso'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
          ),
        ],
      ),
    );
  }
}
