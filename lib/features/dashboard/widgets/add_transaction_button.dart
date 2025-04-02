import 'package:flutter/material.dart';

import 'package:personal_finance/features/dashboard/widgets/add_transaction_modal.dart';

class AddTransactionButton extends StatelessWidget {
  const AddTransactionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed:
          () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (BuildContext context) => const AddTransactionModal(),
          ),
      icon: const Icon(Icons.add),
      label: const Text('Agregar'),
    );
  }
}
