import 'package:flutter/material.dart';
import '../../domain/entities/balance_summary_entity.dart';
import 'package:intl/intl.dart';

class BalanceCard extends StatelessWidget {
  final BalanceSummaryEntity balance;

  const BalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.simpleCurrency(decimalDigits: 2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormatter.format(balance.totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceItem(
                context,
                label: 'Income',
                amount: balance.totalIncome,
                icon: Icons.arrow_upward,
                color: Colors.greenAccent,
              ),
              _buildBalanceItem(
                context,
                label: 'Expenses',
                amount: balance.totalExpenses,
                icon: Icons.arrow_downward,
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context, {
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final currencyFormatter = NumberFormat.simpleCurrency(decimalDigits: 2);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              currencyFormatter.format(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
