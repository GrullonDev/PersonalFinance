import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/quick_finance_bloc.dart';
import '../bloc/quick_finance_event.dart';
import '../bloc/quick_finance_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_entry_input.dart';
import '../widgets/transactions_list.dart';

class QuickFinanceHomePage extends StatelessWidget {
  const QuickFinanceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<QuickFinanceBloc>()..add(LoadQuickFinance()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Quick Finance',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                context.read<QuickFinanceBloc>().add(SyncTransactionsEvent());
              },
            ),
          ],
        ),
        body: BlocBuilder<QuickFinanceBloc, QuickFinanceState>(
          builder: (context, state) {
            if (state.status == QuickFinanceStatus.loading && state.transactions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BalanceCard(balance: state.balance),
                  const SizedBox(height: 32),
                  const Text(
                    'Quick Entry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  QuickEntryInput(
                    onAdd: (double amount, TransactionType type, String note) {
                      final transaction = TransactionEntity(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        userId: 'current-user', // Should come from Auth
                        type: type,
                        amount: amount,
                        note: note,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        syncStatus: SyncStatus.pending,
                        version: 1,
                        deviceId: 'current-device',
                      );
                      context.read<QuickFinanceBloc>().add(AddTransactionEvent(transaction));
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TransactionsList(
                    transactions: state.transactions,
                    onDelete: (id) {
                      context.read<QuickFinanceBloc>().add(DeleteTransactionEvent(id));
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
