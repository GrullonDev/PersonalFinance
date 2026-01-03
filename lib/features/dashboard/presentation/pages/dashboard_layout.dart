import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:personal_finance/features/dashboard/domain/entities/dashboard_models.dart';
import 'package:personal_finance/features/dashboard/presentation/providers/dashboard_logic.dart';
import 'package:personal_finance/features/dashboard/presentation/widgets/balance_card.dart';
import 'package:personal_finance/features/dashboard/presentation/widgets/periodic_selector.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardLayout extends StatelessWidget {
  const DashboardLayout({super.key});

  @override
  Widget build(BuildContext context) => Consumer<DashboardLogic>(
    builder: (BuildContext context, DashboardLogic logic, _) {
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
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
            colors: <Color>[Colors.grey.shade50, Colors.grey.shade100],
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
                    padding: const EdgeInsets.only(left: 8, bottom: 16, top: 8),
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
                      final PeriodFilter period = PeriodFilter.values
                          .firstWhere((PeriodFilter e) => e.name == value);
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

  Widget _buildExpensesChart(BuildContext context, DashboardLogic logic) {
    final List<ChartData> chartData = logic.getChartData();

    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    final FinanceColors colors = Theme.of(context).extension<FinanceColors>()!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.glassBackground,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.pie_chart_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Distribución',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: SfCircularChart(
              series: <CircularSeries<ChartData, String>>[
                DoughnutSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.category,
                  yValueMapper: (ChartData data, _) => data.amount,
                  pointColorMapper: (ChartData data, _) => data.color,
                  innerRadius: '70%',
                  radius: '100%',
                  startAngle: 15,
                  endAngle: 15 + 360,
                  cornerStyle: CornerStyle.bothCurve,
                ),
              ],
              legend: Legend(
                isVisible: true,
                position: LegendPosition.right,
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                ),
                iconHeight: 10,
                iconWidth: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context, DashboardLogic logic) {
    final Map<String, double> expensesByCategory = logic.expensesByCategory;

    if (expensesByCategory.isEmpty) return const SizedBox.shrink();

    return _buildGlassListGroup(
      context,
      title: 'Gastos por Categoría',
      icon: Icons.category_rounded,
      color: const Color(0xFFFF2D55),
      children:
          expensesByCategory.entries
              .map(
                (entry) => _buildListItem(
                  context,
                  title: entry.key,
                  subtitle:
                      '${logic.formatPercentage(entry.value, logic.totalExpenses)} del total',
                  amount: '-${logic.formatCurrency(entry.value)}',
                  color: logic.getCategoryColor(entry.key),
                  isNegative: true,
                ),
              )
              .toList(),
    );
  }

  Widget _buildGlassGoalCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required double progress,
    required Color color,
  }) {
    final FinanceColors colors = Theme.of(context).extension<FinanceColors>()!;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.glassBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, DashboardLogic logic) {
    // Map both lists to TransactionItem
    final List<TransactionItem> allTransactions = [
      ...logic.sortedIncomes.map(
        (i) => TransactionItem(
          title: i.title,
          amount: i.amount,
          date: i.date,
          isIncome: true,
        ),
      ),
      ...logic.sortedExpenses.map(
        (e) => TransactionItem(
          title: e.title,
          amount: e.amount,
          date: e.date,
          isIncome: false,
        ),
      ),
    ];

    // Sort logic
    allTransactions.sort((a, b) => b.date.compareTo(a.date));

    final recentTransactions = allTransactions.take(10).toList();

    return _buildGlassListGroup(
      context,
      title: 'Transacciones Recientes',
      icon: Icons.list_alt_rounded,
      color: Colors.blueAccent,
      children:
          recentTransactions.map((t) {
            return _buildListItem(
              context,
              title: t.title,
              subtitle: logic.formatDate(t.date),
              amount:
                  '${t.isIncome ? '+' : '-'}${logic.formatCurrency(t.amount)}',
              color: t.isIncome ? Colors.green : Colors.red,
              isNegative: !t.isIncome,
            );
          }).toList(),
    );
  }

  Widget _buildIncomeList(DashboardLogic logic) {
    final List<IncomeEntity> incomes = logic.filteredIncomes;
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
              (IncomeEntity income) => Container(
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
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color:
                isNegative ? const Color(0xFFFF2D55) : const Color(0xFF00E676),
          ),
        ),
      ],
    ),
  );

  Widget _buildPersonalizedRecommendations(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Para ti',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fondo de Emergencia',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Te recomendamos guardar al menos 3 meses de gastos.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.savings_outlined, color: Colors.white),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildSavingGoals(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Metas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text('Ver todo')),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildGlassGoalCard(
              context,
              title: 'Viaje Playa',
              icon: Icons.beach_access,
              progress: 0.65,
              color: Colors.cyan,
            ),
            const SizedBox(width: 16),
            _buildGlassGoalCard(
              context,
              title: 'Nuevo Auto',
              icon: Icons.directions_car,
              progress: 0.3,
              color: Colors.purple,
            ),
            const SizedBox(width: 16),
            _buildGlassGoalCard(
              context,
              title: 'MacBook',
              icon: Icons.laptop_mac,
              progress: 0.15,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildSummaryCards(BuildContext context, DashboardLogic logic) => Row(
    children: <Widget>[
      Expanded(
        child: _buildGlassSummaryCard(
          context,
          title: 'INGRESOS',
          amount: logic.totalIncomes,
          icon: Icons.arrow_upward_rounded,
          color: const Color(0xFF00E676),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _buildGlassSummaryCard(
          context,
          title: 'GASTOS',
          amount: logic.totalExpenses,
          icon: Icons.arrow_downward_rounded,
          color: const Color(0xFFFF2D55),
        ),
      ),
    ],
  );
}
