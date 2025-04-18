import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
import 'package:personal_finance/features/dashboard/page/dashboard_layout.dart';
import 'package:personal_finance/features/dashboard/widgets/add_transaction_button.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardLogic>(
      create: (BuildContext context) => DashboardLogic(),
      child: Scaffold(
        appBar: AppBar(
          title: const Hero(
            tag: 'start-button',
            child: Text('Finanzas Personales'),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: const DashboardLayout(),
        floatingActionButton: const AddTransactionButton(),
      ),
    );
  }
}
