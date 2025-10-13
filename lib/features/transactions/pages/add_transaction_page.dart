import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:personal_finance/features/transactions/logic/add_transaction_logic.dart';
import 'package:personal_finance/features/transactions/widgets/add_transaction_view.dart';

class AddTransactionPage extends StatelessWidget {
  const AddTransactionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<AddTransactionLogic>(
        create: (_) => AddTransactionLogic(),
        child: const AddTransactionView(),
      );
}
