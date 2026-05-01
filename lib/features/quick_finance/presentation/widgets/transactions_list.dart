import 'package:flutter/material.dart';
import '../../domain/entities/transaction_entity.dart';
import 'transaction_tile.dart';

/// Lista de transacciones con estado vacío y transiciones animadas.
///
/// Las transacciones ya llegan filtradas (sin soft-deleted) y ordenadas
/// por [createdAt] descendente desde la capa de datos.
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: transactions.isEmpty
          ? const _EmptyState(key: ValueKey('empty'))
          : _List(
              key: const ValueKey('list'),
              transactions: transactions,
              onDelete: onDelete,
            ),
    );
  }
}

// ── Lista con items ───────────────────────────────────────────────────────────

class _List extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final void Function(String id) onDelete;

  const _List({super.key, required this.transactions, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return TransactionTile(
          key: ValueKey(tx.id),
          transaction: tx,
          onDelete: () => onDelete(tx.id),
        );
      },
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin transacciones aún',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Usa la entrada rápida para registrar un movimiento',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
