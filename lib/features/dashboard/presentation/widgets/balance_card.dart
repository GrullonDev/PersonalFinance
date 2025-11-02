import 'package:flutter/material.dart';

import 'package:personal_finance/utils/app_localization.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({required this.balance, super.key});

  final double balance;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isPositive = balance >= 0;
    final Color balanceColor =
        isPositive ? theme.colorScheme.secondary : theme.colorScheme.error;

    return Card(
      elevation: 10,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors:
                isPositive
                    ? <Color>[Colors.green.shade50, Colors.green.shade100]
                    : <Color>[Colors.red.shade50, Colors.red.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: balanceColor.withAlpha(100)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: balanceColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context)!.totalBalance,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: balanceColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: balanceColor,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder:
                  (Widget child, Animation<double> animation) =>
                      ScaleTransition(scale: animation, child: child),
              child: Text(
                '${isPositive ? '+' : ''}${AppLocalizations.of(context)!.currencyFormatter.format(balance)}',
                key: ValueKey<double>(balance),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: balanceColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: balanceColor.withAlpha(50)),
              ),
              child: Text(
                isPositive
                    ? AppLocalizations.of(context)!.positiveBalance
                    : AppLocalizations.of(context)!.negativeBalance,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: balanceColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
