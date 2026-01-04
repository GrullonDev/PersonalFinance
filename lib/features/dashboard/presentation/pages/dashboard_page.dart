import 'package:flutter/material.dart';
import 'package:personal_finance/features/dashboard/domain/entities/dashboard_models.dart';
import 'package:personal_finance/features/dashboard/presentation/providers/dashboard_logic.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:personal_finance/features/dashboard/presentation/widgets/budget_card.dart';
import 'package:personal_finance/features/dashboard/presentation/widgets/recent_transaction_item.dart';
import 'package:personal_finance/features/dashboard/presentation/widgets/recommendation_card.dart';
import 'package:personal_finance/features/dashboard/presentation/widgets/savings_goal_card.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_detail.dart';
import 'package:personal_finance/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/responsive.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<DashboardLogic>(
    create: (_) {
      final logic = getIt<DashboardLogic>();
      logic.loadDashboardData();
      return logic;
    },
    child: const _DashboardContent(),
  );
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) => Consumer<DashboardLogic>(
    builder: (BuildContext context, DashboardLogic logic, _) {
      if (logic.isLoading && !logic.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!logic.hasData && !logic.isLoading) {
        return _buildEmptyState();
      }

      if (context.isMobile) {
        return _buildMobileLayout(context, logic);
      }
      return _buildWideLayout(context, logic);
    },
  );

  Widget _buildMobileLayout(BuildContext context, DashboardLogic logic) =>
      RefreshIndicator(
        onRefresh: () async {
          await logic.loadDashboardData();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            // Header con Balance
            SliverToBoxAdapter(child: _buildHeader(context, logic)),

            // Contenido principal
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        BudgetCard(
                          title:
                              logic.activeBudget?.nombre ??
                              'Presupuesto Mensual',
                          amount:
                              logic.activeBudget != null
                                  ? logic.activeBudget!.montoAsDouble
                                  : (logic.totalIncomes > 0
                                      ? logic.totalIncomes
                                      : 1000),
                          spent: logic.totalExpenses,
                        ),
                        const SizedBox(height: 24),
                        _buildSavingsGoalsSection(context, logic),
                        const SizedBox(height: 24),
                        _buildRecentTransactionsSection(logic, context),
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
                        _buildRecommendationsSection(context, logic),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildWideLayout(BuildContext context, DashboardLogic logic) =>
      RefreshIndicator(
        onRefresh: () async {
          await logic.loadDashboardData();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(child: _buildHeader(context, logic)),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Left Column: Finances & Savings
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: <Widget>[
                                BudgetCard(
                                  title:
                                      logic.activeBudget?.nombre ??
                                      'Presupuesto Mensual',
                                  amount:
                                      logic.activeBudget != null
                                          ? logic.activeBudget!.montoAsDouble
                                          : (logic.totalIncomes > 0
                                              ? logic.totalIncomes
                                              : 1000),
                                  spent: logic.totalExpenses,
                                ),
                                const SizedBox(height: 32),
                                const SizedBox(height: 32),
                                _buildSavingsGoalsSection(context, logic),
                                const SizedBox(height: 32),
                                if (logic.shouldShowExpensesChart)
                                  _buildExpensesChart(logic),
                              ],
                            ),
                          ),
                          const SizedBox(width: 40),
                          // Right Column: Activity & Tips
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: <Widget>[
                                _buildRecentTransactionsSection(logic, context),
                                const SizedBox(height: 32),
                                if (logic.shouldShowExpensesChart) ...<Widget>[
                                  _buildExpensesList(logic),
                                  const SizedBox(height: 32),
                                ],
                                if (logic.shouldShowIncomesList) ...<Widget>[
                                  _buildIncomeList(logic),
                                  const SizedBox(height: 32),
                                ],
                                _buildRecommendationsSection(context, logic),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildHeader(BuildContext context, DashboardLogic logic) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    // Crear variantes del color primario verde para el gradiente
    final lightGreen = Color.lerp(primaryColor, Colors.white, 0.2)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[primaryColor, lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Period Selector
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PeriodFilter>(
                      value: logic.selectedPeriod,
                      dropdownColor: primaryColor.withOpacity(0.95),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (PeriodFilter? newValue) {
                        if (newValue != null) {
                          logic.changePeriod(newValue);
                        }
                      },
                      items:
                          PeriodFilter.values
                              .map<DropdownMenuItem<PeriodFilter>>(
                                (PeriodFilter value) =>
                                    DropdownMenuItem<PeriodFilter>(
                                      value: value,
                                      child: Text(value.label),
                                    ),
                              )
                              .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Balance total
                _buildBalanceHeader(logic),
                const SizedBox(
                  height: 30,
                ), // Extra padding for the overlay effect
                // Summary Cards (Income/Expense) - Overlaying nicely
                _buildSummaryCards(logic),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DashboardLogic logic) => Row(
    children: <Widget>[
      Expanded(
        child: _buildSummaryCard(
          title: 'INGRESOS',
          amount: logic.totalIncomes,
          icon: Icons.arrow_upward,
          color: Colors.white.withAlpha(40),
          textColor: Colors.white,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildSummaryCard(
          title: 'GASTOS',
          amount: logic.totalExpenses,
          icon: Icons.arrow_downward,
          color: Colors.white.withAlpha(40),
          textColor: Colors.white,
        ),
      ),
    ],
  );

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withAlpha(30)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, color: textColor.withAlpha(200), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor.withAlpha(200),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
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

  Widget _buildBalanceHeader(DashboardLogic logic) {
    final bool isPositive = logic.balance >= 0;
    final Color balanceColor = isPositive ? Colors.white : Colors.red.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Saldo total',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${logic.balance.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: balanceColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsGoalsSection(
    BuildContext context,
    DashboardLogic logic,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Text(
            'Metas de Ahorro',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextButton(
            onPressed: () {
              // Ver todas las metas
            },
            child: const Text(
              'Ver todas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (logic.goals.isEmpty)
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.savings_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No hay metas activas',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        )
      else
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: logic.goals.length,
            itemBuilder: (context, index) {
              final goal = logic.goals[index];
              return SavingsGoalCard(
                title: goal.nombre,
                targetAmount: goal.objetivoAsDouble,
                currentAmount: goal.actualAsDouble,
                emoji: goal.icono ?? '🎯',
                deadline: goal.fechaLimite,
              );
            },
          ),
        ),
    ],
  );

  Widget _buildRecentTransactionsSection(
    DashboardLogic logic,
    BuildContext context,
  ) {
    final List<TransactionItem> recentTransactions = logic
        .getRecentTransactions(limit: 10);

    if (recentTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Últimas Transacciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...recentTransactions.map((TransactionItem transaction) {
          final IconData icon = _getIconForTransaction(transaction);
          final String category = _getCategoryForTransaction(transaction);

          return RecentTransactionItem(
            icon: icon,
            title: transaction.title,
            subtitle: category,
            amount: transaction.amount,
            isExpense: !transaction.isIncome,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder:
                      (BuildContext context) => TransactionDetailPage(
                        transaction: TransactionDetail(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: transaction.title,
                          amount: transaction.amount,
                          date: transaction.date,
                          category: category,
                          isExpense: !transaction.isIncome,
                          notes: _getNotesExample(transaction.title),
                        ),
                      ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  String? _getNotesExample(String title) {
    // Ejemplos de notas basadas en el título
    final String lower = title.toLowerCase();
    if (lower.contains('starbucks') || lower.contains('café')) {
      return 'Café con leche y croissant';
    } else if (lower.contains('restaurante')) {
      return 'Almuerzo con colegas';
    } else if (lower.contains('uber') || lower.contains('transporte')) {
      return 'Viaje al trabajo';
    }
    return null;
  }

  IconData _getIconForTransaction(TransactionItem transaction) {
    final String title = transaction.title.toLowerCase();

    if (title.contains('restaurante') || title.contains('comida')) {
      return Icons.restaurant;
    } else if (title.contains('transporte') || title.contains('metro')) {
      return Icons.directions_bus;
    } else if (title.contains('cine') || title.contains('entretenimiento')) {
      return Icons.movie;
    } else if (transaction.isIncome) {
      return Icons.attach_money;
    }

    return Icons.shopping_bag;
  }

  String _getCategoryForTransaction(TransactionItem transaction) {
    final String title = transaction.title.toLowerCase();

    if (title.contains('restaurante') || title.contains('comida')) {
      return 'Comida';
    } else if (title.contains('transporte') || title.contains('metro')) {
      return 'Transporte';
    } else if (title.contains('cine') || title.contains('entretenimiento')) {
      return 'Entretenimiento';
    } else if (transaction.isIncome) {
      return 'Ingreso';
    }

    return 'Compras';
  }

  Widget _buildRecommendationsSection(
    BuildContext context,
    DashboardLogic logic,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text(
        'Recomendaciones Personalizadas',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 170,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: logic.recommendations.length,
          itemBuilder: (context, index) {
            final recommendation = logic.recommendations[index];
            return RecommendationCard(
              icon: recommendation.icon,
              title: recommendation.title,
              description: recommendation.description,
              actionLabel: recommendation.actionLabel,
              accentColor: recommendation.accentColor,
              onActionTap: () {
                // Handle action based on type
                switch (recommendation.actionType) {
                  case RecommendationActionType.createGoal:
                    // Navigate to create goal
                    break;
                  case RecommendationActionType.viewExpenses:
                    // Navigate to expenses view
                    break;
                  case RecommendationActionType.viewInvestments:
                    // Navigate to investments (if exists)
                    break;
                  case RecommendationActionType.none:
                    // No action
                    break;
                }
              },
            );
          },
        ),
      ),
    ],
  );

  Widget _buildExpensesChart(DashboardLogic logic) => Column(
    children: <Widget>[
      const Text(
        'Gastos por Categoría',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 300,
        child: SfCircularChart(
          legend: const Legend(
            isVisible: true,
            overflowMode: LegendItemOverflowMode.wrap,
            position: LegendPosition.bottom,
          ),
          series: <CircularSeries<ChartData, String>>[
            DoughnutSeries<ChartData, String>(
              dataSource: logic.chartData,
              xValueMapper: (ChartData data, _) => data.category,
              yValueMapper: (ChartData data, _) => data.amount,
              pointColorMapper: (ChartData data, _) => data.color,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildExpensesList(DashboardLogic logic) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text(
        'Desglose de Gastos',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 12),
      ...logic
          .getExpenseTransactions(limit: 10)
          .map(
            (TransactionItem transaction) => RecentTransactionItem(
              icon: _getIconForTransaction(transaction),
              title: transaction.title,
              subtitle: _getCategoryForTransaction(transaction),
              amount: transaction.amount,
              onTap: () {},
            ),
          ),
    ],
  );

  Widget _buildIncomeList(DashboardLogic logic) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text(
        'Desglose de Ingresos',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 12),
      ...logic
          .getIncomeTransactions(limit: 10)
          .map(
            (TransactionItem transaction) => RecentTransactionItem(
              icon: _getIconForTransaction(transaction),
              title: transaction.title,
              subtitle: _getCategoryForTransaction(transaction),
              amount: transaction.amount,
              isExpense: false,
              onTap: () {},
            ),
          ),
    ],
  );
}
