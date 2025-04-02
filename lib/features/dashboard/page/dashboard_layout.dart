import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/utils/app_localization.dart';

class DashboardLayout extends StatelessWidget {
  const DashboardLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardLogic>(
      builder: (BuildContext context, DashboardLogic logic, __) {
        return ValueListenableBuilder<Box<Expense>>(
          valueListenable: Hive.box<Expense>('expenses').listenable(),
          builder: (BuildContext context, Box<Expense> expenseBox, _) {
            final List<Expense> expenses = expenseBox.values.toList();
            final double totalGastos = logic.calculateTotalExpenses(expenses);
            final Map<String, double> expensesByCategory = logic
                .calculateExpensesByCategory(expenses);

            // Obtener ingresos desde Hive
            final List<Income> incomes =
                Hive.box<Income>('incomes').values.toList();
            final double totalIngresos = logic.calculateTotalIncome(incomes);
            final double saldo = logic.calculateBalance(
              totalIngresos,
              totalGastos,
            );

            if (expenseBox.isEmpty && incomes.isEmpty) {
              return const Center(
                child: Text('No hay gastos ni ingresos registrados'),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _buildBalanceCard(saldo, context),
                  const SizedBox(height: 16),
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),
                  _buildExpensesChart(expensesByCategory, totalGastos),
                  const SizedBox(height: 16),
                  _buildExpensesList(expensesByCategory, totalGastos),
                  const SizedBox(height: 16),
                  _buildTransactionsList(incomes, expenses),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBalanceCard(double balance, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Text(
              'BALANCE',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(context, balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        _buildPeriodButton('Día'),
        _buildPeriodButton('Semana'),
        _buildPeriodButton('Mes'),
        _buildPeriodButton('Año'),
        _buildPeriodButton('Período'),
      ],
    );
  }

  Widget _buildPeriodButton(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildExpensesChart(
    Map<String, double> expensesByCategory,
    double total,
  ) {
    if (expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<ChartData> chartData =
        expensesByCategory.entries
            .map(
              (MapEntry<String, double> e) =>
                  ChartData(e.key, e.value, _getCategoryColor(e.key)),
            )
            .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'DISTRIBUCIÓN DE GASTOS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.category,
                    yValueMapper: (ChartData data, _) => data.amount,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(
    Map<String, double> expensesByCategory,
    double total,
  ) {
    if (expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'GASTOS POR CATEGORÍA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...expensesByCategory.entries.map((MapEntry<String, double> entry) {
              final String percentage = (entry.value / total * 100)
                  .toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Income> incomes, List<Expense> expenses) {
    final List<_TransactionItem> allTransactions = <_TransactionItem>[
      ...incomes.map(
        (Income i) => _TransactionItem(i.title, i.amount, i.date, true),
      ),
      ...expenses.map(
        (Expense e) => _TransactionItem(e.title, e.amount, e.date, false),
      ),
    ];

    allTransactions.sort(
      (_TransactionItem a, _TransactionItem b) => b.date.compareTo(a.date),
    );

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'ÚLTIMAS TRANSACCIONES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allTransactions.length,
              itemBuilder: (BuildContext context, int index) {
                final _TransactionItem item = allTransactions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                item.isIncome
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.isIncome
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: item.isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${item.date.day}/${item.date.month}/${item.date.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.isIncome ? '+' : '-'}\$${item.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final Map<String, MaterialColor> colors = <String, MaterialColor>{
      'Alimentación': Colors.orange,
      'Transporte': Colors.blue,
      'Hogar': Colors.purple,
      'Entretenimiento': Colors.pink,
      'Compras': Colors.teal,
      'Salud': Colors.red,
      'Créditos': Colors.indigo,
      'Otros': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }
}

class ChartData {
  final String category;
  final double amount;
  final Color color;

  ChartData(this.category, this.amount, this.color);
}

class _TransactionItem {
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;

  _TransactionItem(this.title, this.amount, this.date, this.isIncome);
}

// Añade este método de ayuda en tu clase DashboardLayout
String _formatCurrency(BuildContext context, double amount) {
  return AppLocalizations.of(context)!.currencyFormatter.format(amount);
}
