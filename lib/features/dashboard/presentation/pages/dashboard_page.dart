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
import 'package:personal_finance/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/features/settings/presentation/providers/settings_provider.dart';
import 'package:personal_finance/features/notifications/presentation/providers/notification_inbox_provider.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<DashboardLogic>(
    create: (context) {
      final logic = getIt<DashboardLogic>();
      final isBusiness = context.read<SettingsProvider>().isBusinessMode;
      logic.setProfileType(isBusiness ? 'negocio' : 'personal');
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
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child:
                        !logic.hasData
                            ? _buildModernEmptyState(context)
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (logic.insightMessage != null) ...[
                                  _buildInsightsCard(context, logic),
                                  const SizedBox(height: 24),
                                ],
                                GestureDetector(
                                  onTap:
                                      () => Navigator.pushNamed(
                                        context,
                                        RoutePath.budgetsCrud,
                                      ),
                                  child: BudgetCard(
                                    title:
                                        logic.activeBudget?.nombre ??
                                        'Presupuesto Semanal',
                                    amount:
                                        logic.activeBudget != null
                                            ? logic.activeBudget!.montoAsDouble
                                            : 0,
                                    spent: logic.weeklyBudgetSpent,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildSavingsGoalsSection(context, logic),
                                const SizedBox(height: 24),
                                _buildDebtsOverviewSection(context),
                                const SizedBox(height: 24),
                                _buildRecentTransactionsSection(logic, context),
                                const SizedBox(height: 24),
                                if (logic.shouldShowExpensesChart) ...<Widget>[
                                  _buildExpensesChart(context, logic),
                                  const SizedBox(height: 24),
                                  _buildExpensesList(context, logic),
                                  const SizedBox(height: 24),
                                ],
                                if (logic.shouldShowIncomesList) ...<Widget>[
                                  _buildIncomeList(context, logic),
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

  Widget _buildWideLayout(
    BuildContext context,
    DashboardLogic logic,
  ) => RefreshIndicator(
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child:
                      !logic.hasData
                          ? _buildModernEmptyState(context)
                          : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Left Column: Finances & Savings
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: <Widget>[
                                    if (logic.insightMessage != null) ...[
                                      _buildInsightsCard(context, logic),
                                      const SizedBox(height: 32),
                                    ],
                                    GestureDetector(
                                      onTap: () async {
                                        await Navigator.pushNamed(
                                          context,
                                          RoutePath.budgetsCrud,
                                        );
                                        logic.loadDashboardData();
                                      },
                                      child: BudgetCard(
                                        title:
                                            logic.activeBudget?.nombre ??
                                            'Presupuesto Semanal',
                                        amount:
                                            logic.activeBudget != null
                                                ? logic
                                                    .activeBudget!
                                                    .montoAsDouble
                                                : 0,
                                        spent: logic.weeklyBudgetSpent,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    const SizedBox(height: 32),
                                    _buildSavingsGoalsSection(context, logic),
                                    const SizedBox(height: 32),
                                    _buildDebtsOverviewSection(context),
                                    const SizedBox(height: 32),
                                    if (logic.shouldShowExpensesChart)
                                      _buildExpensesChart(context, logic),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 40),
                              // Right Column: Activity & Tips
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: <Widget>[
                                    _buildRecentTransactionsSection(
                                      logic,
                                      context,
                                    ),
                                    const SizedBox(height: 32),
                                    if (logic
                                        .shouldShowExpensesChart) ...<Widget>[
                                      _buildExpensesList(context, logic),
                                      const SizedBox(height: 32),
                                    ],
                                    if (logic
                                        .shouldShowIncomesList) ...<Widget>[
                                      _buildIncomeList(context, logic),
                                      const SizedBox(height: 32),
                                    ],
                                    _buildRecommendationsSection(
                                      context,
                                      logic,
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
        ),
      ],
    ),
  );

  Widget _buildInsightsCard(BuildContext context, DashboardLogic logic) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.tips_and_updates,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insight',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    logic.insightMessage!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
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
                // ===== MAGIC SWITCH START =====
                if (context.watch<SettingsProvider>().canToggleMode)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildModeTab(
                              context,
                              title: 'Personal',
                              icon: Icons.person,
                              isSelected:
                                  !context
                                      .watch<SettingsProvider>()
                                      .isBusinessMode,
                              onTap: () {
                                context
                                    .read<SettingsProvider>()
                                    .toggleBusinessMode(value: false);
                                logic.setProfileType('personal');
                                logic.loadDashboardData();
                                context.read<TransactionsBloc>().add(
                                  TransactionsLoad(profileType: 'personal'),
                                );
                              },
                            ),
                            _buildModeTab(
                              context,
                              title: 'Negocio',
                              icon: Icons.storefront,
                              isSelected:
                                  context
                                      .watch<SettingsProvider>()
                                      .isBusinessMode,
                              onTap: () {
                                context
                                    .read<SettingsProvider>()
                                    .toggleBusinessMode(value: true);
                                logic.setProfileType('negocio');
                                logic.loadDashboardData();
                                context.read<TransactionsBloc>().add(
                                  TransactionsLoad(profileType: 'negocio'),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ===== MAGIC SWITCH END =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Hola ${context.watch<AuthProvider>().currentUser?.fullName.split(' ').first ?? 'Usuario'} 👋',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Consumer<NotificationInboxProvider>(
                                builder: (context, inboxProvider, _) {
                                  final unreadCount = inboxProvider.unreadCount;
                                  return Stack(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.notifications_outlined,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            RoutePath.notificationsInbox,
                                          );
                                        },
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: primaryColor,
                                                width: 2,
                                              ),
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Text(
                                              unreadCount > 9
                                                  ? '9+'
                                                  : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Así van tus finanzas hoy',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          dropdownColor: primaryColor.withValues(alpha: 0.95),
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
                  ],
                ),
                const SizedBox(height: 20),
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

  Widget _buildModeTab(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white70,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white70,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSummaryCards(DashboardLogic logic) => Row(
    children: <Widget>[
      Expanded(
        child: _buildSummaryCard(
          logic: logic,
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
          logic: logic,
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
    required DashboardLogic logic,
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
          logic.formatCurrency(amount),
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildModernEmptyState(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Ilustración minimalista fintech
          SizedBox(
            height: 160,
            width: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background subtle dashed circle and empty chart
                SizedBox(
                  width: 140,
                  height: 140,
                  child: SfCircularChart(
                    margin: EdgeInsets.zero,
                    series: <CircularSeries<Map<String, dynamic>, String>>[
                      DoughnutSeries<Map<String, dynamic>, String>(
                        animationDuration: 0,
                        dataSource: const [
                          {'x': '', 'y': 100},
                        ],
                        xValueMapper:
                            (Map<String, dynamic> data, _) =>
                                data['x'] as String,
                        yValueMapper:
                            (Map<String, dynamic> data, _) => data['y'] as int,
                        pointColorMapper:
                            (_, __) => Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.05),
                        innerRadius: '85%',
                      ),
                    ],
                  ),
                ),
                // Card 1 (Back)
                Positioned(
                  top: 25,
                  right: 25,
                  child: Transform.rotate(
                    angle: 0.25,
                    child: Container(
                      width: 80,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
                // Card 2 (Front)
                Positioned(
                  top: 45,
                  left: 20,
                  child: Transform.rotate(
                    angle: -0.15,
                    child: Container(
                      width: 90,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.credit_card, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                // Floating Action widget (Graph element)
                Positioned(
                  bottom: 10,
                  right: 30,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            '📉 Aún no tienes movimientos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Empieza agregando tu primer ingreso o gasto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
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
          logic.formatCurrency(logic.balance),
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
          Text(
            'Metas de Ahorro',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, RoutePath.goalsCrud);
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: Theme.of(context).primaryColor,
                tooltip: 'Nueva meta',
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, RoutePath.goalsCrud);
                },
                child: const Text(
                  'Ver todas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (logic.goals.isEmpty)
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.savings_outlined,
                size: 40,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No hay metas activas',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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

  Widget _buildDebtsOverviewSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Préstamos y Tarjetas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, RoutePath.debts);
            },
            child: const Text(
              'Gestionar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Banner to redirect to DebtsPage
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, RoutePath.debts),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.redAccent.shade400, Colors.redAccent.shade700],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.credit_card_outlined, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Control de Deudas',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Usa el método Bola de Nieve o Avalancha',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
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
        Text(
          'Últimas Transacciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
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
      Text(
        'Recomendaciones Personalizadas',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
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
                    Navigator.pushNamed(context, RoutePath.goalsCrud);
                    break;
                  case RecommendationActionType.viewExpenses:
                    _showExpensesDetails(context, logic);
                    break;
                  case RecommendationActionType.viewInvestments:
                    // Navigate to investments (if exists)
                    break;
                  case RecommendationActionType.none:
                    // No action
                    break;
                  case RecommendationActionType.createBudgetAlert:
                    // TODO: Handle this case.
                    throw UnimplementedError();
                }
              },
            );
          },
        ),
      ),
    ],
  );

  Widget _buildExpensesChart(BuildContext context, DashboardLogic logic) =>
      Column(
        children: <Widget>[
          Text(
            'Gastos por Categoría',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
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
                  animationDuration: 0,
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

  Widget _buildExpensesList(BuildContext context, DashboardLogic logic) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Desglose de Gastos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildIncomeList(BuildContext context, DashboardLogic logic) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        'Desglose de Ingresos',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
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

  void _showExpensesDetails(BuildContext context, DashboardLogic logic) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Todos tus Gastos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Has gastado un total de \$${logic.totalExpenses.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: logic.getExpenseTransactions(limit: -1).length,
                    itemBuilder: (context, index) {
                      final tx = logic.getExpenseTransactions(limit: -1)[index];
                      return RecentTransactionItem(
                        icon: _getIconForTransaction(tx),
                        title: tx.title,
                        subtitle: _getCategoryForTransaction(tx),
                        amount: tx.amount,
                        onTap: () {
                          // Opcional: navegar al detalle
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
