import 'package:flutter/material.dart';

import 'package:personal_finance/features/transactions/presentation/widgets/add_transaction_modal.dart';
import 'package:personal_finance/utils/app_localization.dart';

class AddTransactionButton extends StatelessWidget {
  const AddTransactionButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    onPressed:
        () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (BuildContext context) => const AddTransactionModal(),
        ),
    icon: const Icon(Icons.add),
    label: Text(AppLocalizations.of(context)!.add),
  );
}
