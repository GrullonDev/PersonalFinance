import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:personal_finance/features/dashboard/domain/entities/dashboard_models.dart';
import 'package:personal_finance/features/dashboard/presentation/providers/dashboard_logic.dart';
import 'package:personal_finance/features/dashboard/presentation/widgets/budget_card.dart';
import 'package:personal_finance/features/dashboard/presentation/widgets/recent_transaction_item.dart';
import 'package:personal_finance/features/dashboard/presentation/widgets/recommendation_card.dart';
import 'package:personal_finance/features/dashboard/presentation/widgets/savings_goal_card.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_detail.dart';
import 'package:personal_finance/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:provider/provider.dart';

class DashboardLayoutV2 extends StatelessWidget {
  const DashboardLayoutV2({super.key});

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
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      // Refresh lógica
                      await Future<void>.delayed(
                        const Duration(milliseconds: 500),
                      );
                    },
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: <Widget>[
                        // Header con Balance
                        SliverToBoxAdapter(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Colors.blue.shade700,
                                  Colors.blue.shade500,
                                ],
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        const Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              'Finanzas',
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.settings_outlined,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/settings',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Balance total
                                    _buildBalanceHeader(logic),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

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
                                    // Presupuesto Semanal
                                    BudgetCard(
                                      title: 'Presupuesto',
                                      amount: 300,
                                      spent: logic.totalExpenses,
                                    ),

                                    const SizedBox(height: 24),

                                    // Metas de Ahorro
                                    _buildSavingsGoalsSection(context),

                                    const SizedBox(height: 24),

                                    // Últimas Transacciones
                                    _buildRecentTransactionsSection(
                                      logic,
                                      context,
                                    ),

                                    const SizedBox(height: 24),

                                    // Recomendaciones Personalizadas
                                    _buildRecommendationsSection(context),

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
                },
              ),
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

  Widget _buildSavingsGoalsSection(BuildContext context) => Column(
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
      SizedBox(
        height: 200,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: const <Widget>[
            SavingsGoalCard(
              title: 'Viaje a la playa',
              targetAmount: 1000,
              currentAmount: 250,
              emoji: '🐷',
            ),
            SavingsGoalCard(
              title: 'Enganche casa',
              targetAmount: 50000,
              currentAmount: 5000,
              emoji: '🏠',
            ),
            SavingsGoalCard(
              title: 'Nueva computadora',
              targetAmount: 2000,
              currentAmount: 800,
              emoji: '💻',
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildRecentTransactionsSection(
    DashboardLogic logic,
    BuildContext context,
  ) {
    final List<TransactionItem> allTransactions = <TransactionItem>[
      ...logic.getExpenseTransactions(limit: 3),
      ...logic.getIncomeTransactions(limit: 2),
    ]..sort((TransactionItem a, TransactionItem b) => b.date.compareTo(a.date));

    final List<TransactionItem> recentTransactions =
        allTransactions.take(5).toList();

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

  Widget _buildRecommendationsSection(BuildContext context) => Column(
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
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            RecommendationCard(
              icon: '💰',
              title: 'Ahorro',
              description:
                  'Crea un fondo de emergencia. Empieza guardando el equivalente a un mes de tus gastos.',
              actionLabel: 'Empezar a ahorrar',
              accentColor: Colors.orange,
              onActionTap: () {
                // Acción para crear meta de ahorro
              },
            ),
            RecommendationCard(
              icon: '📊',
              title: 'Invierte',
              description:
                  'Descubre oportunidades de inversión de bajo riesgo ideales para principiantes.',
              actionLabel: 'Explorar opciones',
              accentColor: Colors.green,
              onActionTap: () {
                // Acción para explorar inversiones
              },
            ),
            RecommendationCard(
              icon: '💳',
              title: 'Controla gastos',
              description:
                  'Has gastado 80% de tu presupuesto. Revisa tus gastos hormiga.',
              actionLabel: 'Ver detalles',
              accentColor: Colors.red,
              onActionTap: () {
                // Acción para ver gastos
              },
            ),
          ],
        ),
      ),
    ],
  );
}
