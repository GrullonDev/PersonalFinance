import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'package:personal_finance/features/debts/presentation/bloc/debts_bloc.dart';
import 'package:personal_finance/features/debts/presentation/bloc/debts_state.dart';
import 'package:personal_finance/features/debts/presentation/widgets/add_debt_dialog.dart';
import 'package:personal_finance/utils/currency_helper.dart';
import 'package:personal_finance/utils/responsive.dart';
import 'package:personal_finance/utils/theme.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  bool _isSnowballMethod = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FinanceColors>()!;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DebtsBloc, DebtsState>(
          builder: (context, state) {
            if (state.loading && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final debts = state.items;

            final totalDebt = debts.fold<double>(
              0,
              (sum, debt) => sum + debt.currentBalance,
            );

            // Calcular recomendación según método
            // Snowball: Menor saldo primero
            // Avalanche: Mayor interés primero
            final sortedDebts = List<Debt>.from(debts);
            if (_isSnowballMethod) {
              sortedDebts.sort((a, b) => a.currentBalance.compareTo(b.currentBalance));
            } else {
              sortedDebts.sort((a, b) => b.interestRate.compareTo(a.interestRate));
            }

            final recommendedDebt = sortedDebts.isNotEmpty ? sortedDebts.first : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // AppBar Custom
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: context.isMobile ? double.infinity : 1000,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis Deudas',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gestiona y elimina tus deudas inteligentemente',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!context.isMobile)
                      FilledButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const AddDebtDialog(),
                          );
                        },
                        icon: const Icon(Icons.add_card_rounded),
                        label: const Text('Agregar Deuda'),
                      ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: context.isMobile ? double.infinity : 1000,
                  ),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Header Card
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildHeaderCard(context, totalDebt),
                        ),
                      ),

                      // Strategy Selector
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.spaceBetween,
                            runSpacing: 12,
                            spacing: 12,
                            children: [
                              Text(
                                'Estrategia de Pago',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: context.sp(20)),
                              ),
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(
                                    value: true,
                                    label: Text('Bola de Nieve'),
                                  ),
                                  ButtonSegment(
                                    value: false,
                                    label: Text('Avalancha'),
                                  ),
                                ],
                                selected: {_isSnowballMethod},
                                onSelectionChanged: (set) {
                                  setState(() {
                                    _isSnowballMethod = set.first;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // Recommendation Card
                      if (recommendedDebt != null)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: _buildRecommendationCard(
                              context,
                              recommendedDebt,
                              colors,
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // Lista de Deudas
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Detalle de Deudas',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final debt = sortedDebts[index];
                            return _buildDebtItem(context, debt, colors);
                          }, childCount: sortedDebts.length),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
              ),
            ),
              ],
            );
          },
        ),
      ),
      floatingActionButton:
          context.isMobile
              ? FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AddDebtDialog(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nueva Deuda'),
              )
              : null,
    );
  }

  Widget _buildHeaderCard(BuildContext context, double totalDebt) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.redAccent.shade400, Colors.redAccent.shade700],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.redAccent.withValues(alpha: 0.3),
          blurRadius: 30,
          spreadRadius: 5,
          offset: const Offset(0, 15),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance, color: Colors.white, size: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Saldo Pendiente',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: context.sp(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${CurrencyHelper.symbol}${totalDebt.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.sp(36),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lleva el control total de lo que debes',
            style: TextStyle(color: Colors.white70, fontSize: context.sp(14)),
          ),
      ],
    ),
  );

  Widget _buildRecommendationCard(
    BuildContext context,
    Debt recommended,
    FinanceColors colors,
  ) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tips_and_updates_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Sugerencia de Pago',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _isSnowballMethod
              ? 'Con el método Bola de Nieve, ataca primero la deuda con menor saldo para lograr victorias rápidas y ganar motivación.'
              : 'Con el método Avalancha, ataca primero la deuda con mayor tasa de interés para ahorrar más dinero a largo plazo.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amber),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enfócate en:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      recommended.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isSnowballMethod
                        ? '${CurrencyHelper.symbol}${recommended.currentBalance.toStringAsFixed(0)}'
                        : '${recommended.interestRate}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    _isSnowballMethod ? 'Saldo' : 'Interés',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildDebtItem(BuildContext context, Debt debt, FinanceColors colors) {
    final progress = 1 - (debt.currentBalance / debt.originalAmount);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.glassBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tasa: ${debt.interestRate}% anual',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${CurrencyHelper.symbol}${debt.currentBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saldo Restante',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            color:
                progress > 0.8
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Progreso: ${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: context.sp(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Original: ${CurrencyHelper.symbol}${debt.originalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.sp(12),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Próx. Pago: ${DateFormat.MMMd().format(debt.nextPaymentDate)}',
                    style: TextStyle(
                      fontSize: context.sp(13),
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Min: ${CurrencyHelper.symbol}${debt.minimumPayment.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.sp(12),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
