import 'package:flutter/material.dart';

import 'package:personal_finance/features/transactions/presentation/widgets/add_transaction_modal.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/transactions/presentation/bloc/transactions_bloc.dart';

class AddTransactionButton extends StatelessWidget {
  const AddTransactionButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    onPressed: () {
      final TransactionsBloc bloc = context.read<TransactionsBloc>();
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder:
            (BuildContext _) => BlocProvider.value(
              value: bloc,
              child: const AddTransactionModal(),
            ),
      );
    },
    icon: const Icon(Icons.add),
    label: Text(AppLocalizations.of(context)!.add),
  );
}
