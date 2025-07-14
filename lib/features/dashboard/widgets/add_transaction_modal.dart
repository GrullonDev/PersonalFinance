import 'package:flutter/material.dart';

import 'package:personal_finance/features/dashboard/widgets/add_expense_modal.dart';
import 'package:personal_finance/features/dashboard/widgets/add_income_modal.dart';

class AddTransactionModal extends StatelessWidget {
  const AddTransactionModal({super.key});

  @override
  Widget build(BuildContext context) => const DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.arrow_downward), text: 'Gasto'),
              Tab(icon: Icon(Icons.arrow_upward), text: 'Ingreso'),
            ],
          ),
          SizedBox(
            height: 500, // Ajusta este valor si necesitas más espacio
            child: TabBarView(
              children: <Widget>[
                AddExpenseModal(key: ValueKey('expense')),
                AddIncomeModal(key: ValueKey('income')),
              ],
            ),
          ),
        ],
      ),
    );
}
