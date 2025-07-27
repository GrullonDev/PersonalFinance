import 'package:flutter/material.dart';
import 'package:personal_finance/features/dashboard/widgets/add_expense_modal.dart';
import 'package:personal_finance/features/dashboard/widgets/add_income_modal.dart';

class AddTransactionPage extends StatelessWidget {
  const AddTransactionPage({super.key});

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
  Widget build(BuildContext context) => Center(
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
