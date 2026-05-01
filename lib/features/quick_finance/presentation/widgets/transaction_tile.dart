import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../../../core/constants/enums.dart';

/// Fila de transacción con soporte para swipe-to-delete.
///
/// El borrado se confirma deslizando de derecha a izquierda.
/// El BLoC hace soft-delete, por lo que el item desaparece del stream
/// sin necesidad de gestión local adicional.
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
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: _DeleteBackground(),
      child: _TileBody(
        transaction: transaction,
        onDeleteTap: onDelete,
      ),
    );
  }
}

// ── Background visible al deslizar ────────────────────────────────────────────

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
    );
  }
}

// ── Contenido visible del tile ────────────────────────────────────────────────

class _TileBody extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onDeleteTap;

  static final _dateFmt = DateFormat('d MMM  HH:mm', 'es');
  static final _currFmt = NumberFormat.simpleCurrency(decimalDigits: 2);

  const _TileBody({required this.transaction, required this.onDeleteTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final typeColor = isIncome ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono de tipo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              // income = dinero entrando (flecha hacia arriba)
              // expense = dinero saliendo (flecha hacia abajo)
              isIncome
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: typeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Nota + fecha + categoría
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _dateFmt.format(transaction.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    if (transaction.categoryId != null) ...[
                      const SizedBox(width: 6),
                      _CategoryChip(label: transaction.categoryId!),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Importe + indicador de sync
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${_currFmt.format(transaction.amount)}',
                style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (transaction.syncStatus == SyncStatus.pending)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 12,
                    color: Colors.blueAccent.shade100,
                  ),
                ),
            ],
          ),

          // Botón de eliminar (respaldo al swipe)
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleteTap,
            child: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip de categoría ────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$label',
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
