import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/transactions/models/transaction_detail.dart';
import 'package:personal_finance/features/transactions/pages/transaction_detail_page.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.grey[50],
      body: ValueListenableBuilder<Box<Expense>>(
        valueListenable: Hive.box<Expense>('expenses').listenable(),
        builder: (BuildContext context, Box<Expense> box, _) {
          final List<Expense> expenses =
              box.values.toList()
                ..sort((Expense a, Expense b) => b.date.compareTo(a.date));

          if (expenses.isEmpty) {
            return _buildEmptyState();
          }

          // Agrupar por mes
          final Map<String, List<Expense>> expensesByMonth = _groupByMonth(
            expenses,
          );

          return CustomScrollView(
            slivers: <Widget>[
              // Header
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[Colors.red.shade700, Colors.red.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Gastos',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${expenses.length} transacciones',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Total de gastos
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text(
                                  'Total gastado',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '\$${_calculateTotal(expenses).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Lista de gastos agrupados por mes
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children:
                          expensesByMonth.entries.map((MapEntry<String, List<Expense>> entry) => _buildMonthSection(
                              context,
                              entry.key,
                              entry.value,
                            )).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'No hay gastos registrados',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toca el botón + para agregar\ntu primer gasto',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    ),
  );

  Widget _buildMonthSection(
    BuildContext context,
    String monthYear,
    List<Expense> expenses,
  ) {
    final double monthTotal = _calculateTotal(expenses);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                monthYear,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '-\$${monthTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...expenses.map((Expense expense) => _buildExpenseItem(context, expense)),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, Expense expense) => GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder:
                (BuildContext context) => TransactionDetailPage(
                  transaction: TransactionDetail.fromExpense(expense),
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Text(
                        expense.category,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        DateFormat('d MMM', 'es').format(expense.date),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                Text(
                  '-\$${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ],
        ),
      ),
    );

  Map<String, List<Expense>> _groupByMonth(List<Expense> expenses) {
    final Map<String, List<Expense>> grouped = <String, List<Expense>>{};

    for (final Expense expense in expenses) {
      final String monthYear = DateFormat(
        'MMMM yyyy',
        'es',
      ).format(expense.date);
      final String capitalizedMonthYear =
          monthYear[0].toUpperCase() + monthYear.substring(1);

      if (!grouped.containsKey(capitalizedMonthYear)) {
        grouped[capitalizedMonthYear] = <Expense>[];
      }
      grouped[capitalizedMonthYear]!.add(expense);
    }

    return grouped;
  }

  double _calculateTotal(List<Expense> expenses) => expenses.fold(
      0,
      (double sum, Expense expense) => sum + expense.amount,
    );

  IconData _getCategoryIcon(String category) {
    final Map<String, IconData> icons = <String, IconData>{
      'Alimentación': Icons.restaurant,
      'Transporte': Icons.directions_bus,
      'Hogar': Icons.home,
      'Entretenimiento': Icons.movie,
      'Compras': Icons.shopping_bag,
      'Salud': Icons.local_hospital,
      'Créditos': Icons.credit_card,
      'Otros': Icons.more_horiz,
    };
    return icons[category] ?? Icons.receipt;
  }
}
