import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/presentation/widgets/transaction_tile.dart';

class TransactionsList extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final void Function(String id) onDelete;
  final bool hideAmounts;

  /// Called with a pre-filled text string when the user taps a quick-start
  /// chip in the empty state. The parent scrolls to and fills the entry input.
  final void Function(String prefillText)? onQuickStart;

  const TransactionsList({
    required this.transactions,
    required this.onDelete,
    this.hideAmounts = false,
    this.onQuickStart,
    super.key,
  });

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    child:
        transactions.isEmpty
            ? _EmptyState(
              key: const ValueKey('empty'),
              onQuickStart: onQuickStart,
            )
            : _GroupedList(
              key: const ValueKey('list'),
              transactions: transactions,
              onDelete: onDelete,
              hideAmounts: hideAmounts,
            ),
  );
}

// ── Grouped list ──────────────────────────────────────────────────────────────

class _GroupedList extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final void Function(String id) onDelete;
  final bool hideAmounts;

  const _GroupedList({
    required this.transactions,
    required this.onDelete,
    required this.hideAmounts,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  List<Widget> _buildItems() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthFmt = DateFormat('MMMM yyyy', 'es');

    String? lastLabel;
    final items = <Widget>[];

    for (final t in transactions) {
      final tDay = DateTime(
        t.createdAt.year,
        t.createdAt.month,
        t.createdAt.day,
      );
      final String label;

      if (tDay == today) {
        label = 'Hoy';
      } else if (tDay == yesterday) {
        label = 'Ayer';
      } else if (!tDay.isBefore(weekStart)) {
        label = 'Esta semana';
      } else {
        final raw = monthFmt.format(t.createdAt);
        label = raw[0].toUpperCase() + raw.substring(1);
      }

      if (label != lastLabel) {
        items.add(_DateHeader(label: label));
        lastLabel = label;
      }

      items.add(
        TransactionTile(
          key: ValueKey(t.id),
          transaction: t,
          hideAmounts: hideAmounts,
          onDelete: () => onDelete(t.id),
        ),
      );
    }

    return items;
  }
}

// ── Date section header ───────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.3,
      ),
    ),
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final void Function(String)? onQuickStart;

  const _EmptyState({super.key, this.onQuickStart});

  static const _examples = [
    ('-5 café', '☕ Café'),
    ('-10 transporte', '🚌 Transporte'),
    ('+100 ingreso', '💰 Ingreso'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Empieza con tu último gasto',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Registra lo que gastas para ver\ntu resumen financiero',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Quick-start chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (raw, label) in _examples) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onQuickStart?.call(raw);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),

          const SizedBox(height: 14),
          Text(
            'Ej: -80 comida  •  +500 salario  •  15 taxi',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
