import 'package:flutter/material.dart';

import 'package:personal_finance/features/transactions/widgets/add_transaction_modal.dart';

class AddTransactionFAB extends StatelessWidget {
  const AddTransactionFAB({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    onPressed: () {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) => const AddTransactionModal(),
      );
    },
    child: const Icon(Icons.add),
  );
}
