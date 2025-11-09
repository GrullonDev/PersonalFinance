import 'package:flutter/material.dart';

import 'package:personal_finance/features/transactions/presentation/widgets/add_transaction_modal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/transactions/presentation/bloc/transactions_bloc.dart';

class AddTransactionFAB extends StatelessWidget {
  const AddTransactionFAB({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    onPressed: () {
      final TransactionsBloc bloc = context.read<TransactionsBloc>();
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder:
            (BuildContext _) => BlocProvider.value(
              value: bloc,
              child: const AddTransactionModal(),
            ),
      );
    },
    child: const Icon(Icons.add),
  );
}
