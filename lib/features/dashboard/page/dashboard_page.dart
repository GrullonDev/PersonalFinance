import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
import 'package:personal_finance/features/dashboard/page/dashboard_layout.dart';
import 'package:personal_finance/features/dashboard/widgets/add_expense_modal.dart';
import 'package:personal_finance/features/dashboard/widgets/add_income_modal.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardLogic>(
      create: (BuildContext context) => DashboardLogic(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finanzas Personales'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const DashboardLayout(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder:
                  (BuildContext context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: const _AddTransactionSelector(),
                  ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _AddTransactionSelector extends StatelessWidget {
  const _AddTransactionSelector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.arrow_upward, color: Colors.green),
            title: const Text('Agregar Ingreso'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder:
                    (BuildContext context) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: const AddIncomeModal(),
                    ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_downward, color: Colors.red),
            title: const Text('Agregar Gasto'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder:
                    (BuildContext context) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: const AddExpenseModal(),
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
