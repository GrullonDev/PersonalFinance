import 'package:flutter/material.dart';

class BudgetCard extends StatelessWidget {
  final String title;
  final double amount;
  final double spent;
  final String period;

  const BudgetCard({
    required this.title,
    required this.amount,
    required this.spent,
    this.period = 'Semanal',
    super.key,
  });

  double get percentage =>
      amount > 0 ? (spent / amount * 100).clamp(0, 100) : 0;
  double get remaining => amount - spent;
  bool get isOverBudget => spent > amount;

  @override
  Widget build(BuildContext context) {
    final bool hasNoBudget = amount <= 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: hasNoBudget
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : isOverBudget
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: <Color>[
              hasNoBudget
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : isOverBudget
                      ? Colors.red.shade50
                      : Colors.green.shade50,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        hasNoBudget
                            ? Icons.account_balance_wallet_outlined
                            : Icons.account_balance_wallet,
                        color: hasNoBudget
                            ? Theme.of(context).colorScheme.primary
                            : isOverBudget
                                ? Colors.red[700]
                                : Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hasNoBudget)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOverBudget
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red[700] : Colors.green[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (hasNoBudget) ...[
              Center(
                child: Column(
                  children: [
                    Text(
                      'No tienes un presupuesto asignado',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Asignar Presupuesto',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    spent.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isOverBudget
                          ? Colors.red[700]
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    ' / ${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget ? Colors.red : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isOverBudget)
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sobrepasaste tu presupuesto',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '¡Buen manejo de gastos!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Editar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

