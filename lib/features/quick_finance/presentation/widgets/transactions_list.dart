import 'package:flutter/material.dart';
import '../../domain/entities/transaction_entity.dart';
import 'transaction_tile.dart';

class TransactionsList extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final void Function(String id) onDelete;

  const TransactionsList({
    super.key,
    required this.transactions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final visibleTransactions = transactions.where((t) => t.deletedAt == null).toList();

    if (visibleTransactions.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleTransactions.length,
      itemBuilder: (context, index) {
        final transaction = visibleTransactions[index];
        return TransactionTile(
          transaction: transaction,
          onDelete: () => onDelete(transaction.id),
        );
      },
    );
  }
}
