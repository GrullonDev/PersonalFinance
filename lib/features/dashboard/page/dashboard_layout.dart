import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_models.dart';
import 'package:personal_finance/features/dashboard/widgets/balance_card.dart';
import 'package:personal_finance/features/dashboard/widgets/periodic_selector.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';

class DashboardLayout extends StatelessWidget {
  const DashboardLayout({super.key});

  @override
  Widget build(BuildContext context) => Consumer<DashboardLogic>(
    builder:
        (
          BuildContext context,
          DashboardLogic logic,
          _,
        ) => ValueListenableBuilder<Box<Expense>>(
          valueListenable: Hive.box<Expense>('expenses').listenable(),
          builder:
              (
                BuildContext context,
                Box<Expense> expenseBox,
                _,
              ) => ValueListenableBuilder<Box<Income>>(
                valueListenable: Hive.box<Income>('incomes').listenable(),
                builder: (BuildContext context, Box<Income> incomeBox, _) {
                  if (!logic.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay transacciones registradas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tu primer gasto o ingreso\ntocando el botón +',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.grey.shade50,
                          Colors.grey.shade100,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SafeArea(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  bottom: 16,
                                  top: 8,
                                ),
                                child: Text(
                                  'Finanzas',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              BalanceCard(balance: logic.balance),
                              const SizedBox(height: 24),
                              PeriodSelector(
                                selected: logic.selectedPeriod.name,
                                onSelect: (String value) {
                                  final PeriodFilter period = PeriodFilter
                                      .values
                                      .firstWhere(
                                        (PeriodFilter e) => e.name == value,
                                      );
                                  logic.changePeriod(period);
                                },
                              ),
                              const SizedBox(height: 24),
                              _buildSummaryCards(logic),
                              const SizedBox(height: 24),
                              _buildSavingGoals(),
                              const SizedBox(height: 24),
                              if (logic.shouldShowExpensesChart) ...<Widget>[
                                _buildExpensesChart(logic),
                                const SizedBox(height: 24),
                                _buildExpensesList(logic),
                                const SizedBox(height: 24),
                              ],
                              if (logic.shouldShowIncomesList) ...<Widget>[
                                _buildIncomeList(logic),
                                const SizedBox(height: 24),
                              ],
                              if (logic.shouldShowTransactions) ...<Widget>[
                                _buildTransactionsList(logic),
                                const SizedBox(height: 24),
                              ],
                              _buildPersonalizedRecommendations(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
        ),
  );

  Widget _buildSummaryCards(DashboardLogic logic) => Row(
    children: <Widget>[
      Expanded(
        child: _buildSummaryCard(
          title: 'INGRESOS',
          amount: logic.totalIncomes,
          icon: Icons.arrow_upward,
          gradient: const LinearGradient(
            colors: <Color>[Colors.green, Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildSummaryCard(
          title: 'GASTOS',
          amount: logic.totalExpenses,
          icon: Icons.arrow_downward,
          gradient: const LinearGradient(
            colors: <Color>[Colors.red, Color(0xFFF44336)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    ],
  );

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required LinearGradient gradient,
  }) => Card(
    elevation: 8,
    shadowColor: Colors.black38,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: gradient,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${title == 'INGRESOS' ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total ${title.toLowerCase()}',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildExpensesChart(DashboardLogic logic) {
    final List<ChartData> chartData = logic.getChartData();

    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'DISTRIBUCIÓN DE GASTOS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: SfCircularChart(
                series: <CircularSeries<ChartData, String>>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.category,
                    yValueMapper: (ChartData data, _) => data.amount,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    innerRadius: '60%',
                  ),
                ],
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(DashboardLogic logic) {
    final Map<String, double> expensesByCategory = logic.expensesByCategory;
    final double total = logic.totalExpenses;

    if (expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'GASTOS POR CATEGORÍA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...expensesByCategory.entries.map((MapEntry<String, double> entry) {
              final String percentage = logic.formatPercentage(
                entry.value,
                total,
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: logic.getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: logic
                                .getCategoryColor(entry.key)
                                .withAlpha(50),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            percentage,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      logic.formatCurrency(entry.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red,
                      ),
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

  Widget _buildIncomeList(DashboardLogic logic) {
    final List<Income> incomes = logic.filteredIncomes;
    final double total = logic.totalIncomes;

    if (incomes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'INGRESOS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...incomes.map(
              (Income income) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.green,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            income.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            logic.formatDate(income.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      logic.formatCurrency(income.amount),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (total > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withAlpha(50)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total ingresos: +${logic.formatCurrency(total)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingGoals() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              'Metas de Ahorro',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Ver todas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
      Row(
        children: <Widget>[
          Expanded(
            child: _buildSavingGoalCard(
              title: 'Viaje a la playa',
              icon: Icons.beach_access,
              progress: 0.25,
              current: 250,
              target: 1000,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSavingGoalCard(
              title: 'Enganche casa',
              icon: Icons.home,
              progress: 0.10,
              current: 5000,
              target: 50000,
              color: Colors.brown.shade300,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildSavingGoalCard({
    required String title,
    required IconData icon,
    required double progress,
    required double current,
    required double target,
    required Color color,
  }) => Card(
    elevation: 4,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${current.toInt()} / \$${target.toInt()}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPersonalizedRecommendations() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 16),
        child: Text(
          'Recomendaciones Personalizadas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
      ),
      Row(
        children: <Widget>[
          Expanded(
            child: _buildRecommendationCard(
              title: 'Crea un fondo de emergencia',
              description:
                  'Empieza guardando el equivalente a un mes de tus gastos. ¡Cada peso cuenta!',
              actionText: 'Empezar a ahorrar',
              icon: Icons.savings_outlined,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildRecommendationCard(
              title: 'Invierte para principiantes',
              description:
                  'Descubre opciones de inversión de bajo riesgo ideales para principiantes.',
              actionText: 'Explorar',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildRecommendationCard({
    required String title,
    required String description,
    required String actionText,
    required IconData icon,
    required Color color,
  }) => Card(
    elevation: 4,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title.split(' ').first,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildTransactionsList(DashboardLogic logic) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              'Últimas Transacciones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Ver todas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      // Sección de Ingresos
      if (logic.hasIncomes) ...<Widget>[
        _buildTransactionSection(
          'INGRESOS',
          Icons.arrow_upward,
          Colors.green,
          logic.getIncomeTransactions(),
          logic,
        ),
        const SizedBox(height: 20),
      ],

      // Sección de Gastos
      if (logic.hasExpenses) ...<Widget>[
        _buildTransactionSection(
          'GASTOS',
          Icons.arrow_downward,
          Colors.red,
          logic.getExpenseTransactions(),
          logic,
        ),
      ],
    ],
  );

  Widget _buildTransactionSection(
    String title,
    IconData icon,
    Color color,
    List<TransactionItem> transactions,
    DashboardLogic logic,
  ) => Card(
    elevation: 4,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${transactions.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (BuildContext context, int index) {
              final TransactionItem item = transactions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withAlpha(15)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withAlpha(15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item.title.toLowerCase().contains('restaurante') ||
                                item.title.toLowerCase().contains('comida')
                            ? Icons.restaurant
                            : item.title.toLowerCase().contains('metro') ||
                                item.title.toLowerCase().contains('transporte')
                            ? Icons.directions_bus
                            : item.title.toLowerCase().contains('cine') ||
                                item.title.toLowerCase().contains(
                                  'entretenimiento',
                                )
                            ? Icons.movie
                            : icon,
                        color: color,
                        size: 22,
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
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title.toLowerCase().contains('restaurante') ||
                                    item.title.toLowerCase().contains('comida')
                                ? 'Comida'
                                : item.title.toLowerCase().contains('metro') ||
                                    item.title.toLowerCase().contains(
                                      'transporte',
                                    )
                                ? 'Transporte'
                                : item.title.toLowerCase().contains('cine') ||
                                    item.title.toLowerCase().contains(
                                      'entretenimiento',
                                    )
                                ? 'Entretenimiento'
                                : logic.formatDate(item.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.isIncome ? '+' : '-'}${logic.formatCurrency(item.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (transactions.length >= 5)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Mostrando 5 de ${title == 'INGRESOS' ? logic.sortedIncomes.length : logic.sortedExpenses.length} transacciones',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
