import 'package:flutter/material.dart';
import 'package:personal_finance/features/dashboard/widgets/add_expense_modal.dart';
import 'package:personal_finance/features/dashboard/widgets/add_income_modal.dart';

class AddTransactionPage extends StatelessWidget {
  const AddTransactionPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Agregar'),
        bottom: const TabBar(
          tabs: <Widget>[
            Tab(icon: Icon(Icons.arrow_downward), text: 'Gasto'),
            Tab(icon: Icon(Icons.arrow_upward), text: 'Ingreso'),
          ],
        ),
      ),
      body: const TabBarView(
        children: <Widget>[
          AddExpenseModal(key: ValueKey<String>('expense')),
          AddIncomeModal(key: ValueKey<String>('income')),
        ],
      ),
    ),
  );
}
