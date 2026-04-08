import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../../../core/constants/enums.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.simpleCurrency(decimalDigits: 2);
    final dateFormatter = DateFormat.yMMMd().add_jm();
    final isIncome = transaction.type == TransactionType.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isIncome ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note.isEmpty ? (isIncome ? 'Income' : 'Expense') : transaction.note,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  dateFormatter.format(transaction.createdAt),
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${currencyFormatter.format(transaction.amount)}',
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (transaction.syncStatus == SyncStatus.pending)
                const Icon(Icons.sync, size: 12, color: Colors.blueAccent),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
