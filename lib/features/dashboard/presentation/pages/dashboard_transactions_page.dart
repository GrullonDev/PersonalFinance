import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:personal_finance/features/dashboard/presentation/widgets/periodic_selector.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';
import 'package:personal_finance/utils/widgets/animated_counter.dart';

class DashboardTransactionsPage extends StatefulWidget {
  const DashboardTransactionsPage({super.key});

  @override
  State<DashboardTransactionsPage> createState() =>
      _DashboardTransactionsPageState();
}

class _DashboardTransactionsPageState extends State<DashboardTransactionsPage> {
  String _period = 'all';
  String _type = 'all'; // all | ingreso | gasto

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // Carga todo desde backend; el filtrado es local en la app
    context.read<TransactionsBloc>().add(TransactionsLoad());
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async => _load(),
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        PeriodSelector(
          selected: _period,
          onSelect: (String p) {
            setState(() => _period = p);
            _load();
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            FilterChip(
              label: const Text('Todos'),
              selected: _type == 'all',
              onSelected: (_) => setState(() => _type = 'all'),
            ),
            FilterChip(
              label: const Text('Ingresos'),
              selected: _type == 'ingreso',
              onSelected: (_) => setState(() => _type = 'ingreso'),
            ),
            FilterChip(
              label: const Text('Gastos'),
              selected: _type == 'gasto',
              onSelected: (_) => setState(() => _type = 'gasto'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (BuildContext context, TransactionsState state) {
            if (state.loading && state.items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final List<TransactionBackend> filtered = _applyFilter(state.items);
            final double ingresos = filtered
                .where(
                  (TransactionBackend t) => t.tipo.toLowerCase() == 'ingreso',
                )
                .fold<double>(
                  0,
                  (double a, TransactionBackend b) => a + b.montoAsDouble,
                );
            final double gastos = filtered
                .where(
                  (TransactionBackend t) => t.tipo.toLowerCase() == 'gasto',
                )
                .fold<double>(
                  0,
                  (double a, TransactionBackend b) => a + b.montoAsDouble,
                );
            final double balance = ingresos - gastos;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _BalanceCard(balance: balance),
                const SizedBox(height: 16),
                _IncomeExpensesCard(ingresos: ingresos, gastos: gastos),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: <Widget>[
                        const Text('Movimientos'),
                        AnimatedCounter(
                          value: filtered.length.toDouble(),
                          decimals: 0,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Transacciones (${filtered.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...filtered.map((TransactionBackend t) {
                  final bool isIngreso = t.tipo.toLowerCase() == 'ingreso';
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isIngreso ? Icons.trending_up : Icons.trending_down,
                        color: isIngreso ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        t.descripcion.isEmpty
                            ? '(sin descripción)'
                            : t.descripcion,
                      ),
                      subtitle: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              '${t.fecha.day}/${t.fecha.month}/${t.fecha.year} · Cat #${t.categoriaId}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (t.esRecurrente)
                            const Icon(
                              Icons.refresh,
                              size: 16,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                      trailing: Text(
                        '${isIngreso ? '+' : '-'}\$${t.montoAsDouble.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isIngreso ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
                if (filtered.isEmpty && !state.loading)
                  const EmptyState(
                    title: 'Sin transacciones',
                    message: 'No hay movimientos en este período.',
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );

  List<TransactionBackend> _applyFilter(List<TransactionBackend> all) {
    final DateTimeRange? range = _rangeFor(_period);
    List<TransactionBackend> result = List<TransactionBackend>.from(all);
    if (range != null) {
      result =
          result
              .where(
                (TransactionBackend t) =>
                    !t.fecha.isBefore(range.start) &&
                    t.fecha.isBefore(range.end),
              )
              .toList();
    }
    if (_type != 'all') {
      result =
          result
              .where((TransactionBackend t) => t.tipo.toLowerCase() == _type)
              .toList();
    }
    return result..sort(
      (TransactionBackend a, TransactionBackend b) =>
          b.fecha.compareTo(a.fecha),
    );
  }

  DateTimeRange? _rangeFor(String p) {
    final DateTime now = DateTime.now();
    switch (p) {
      case 'day':
        final DateTime start = DateTime(now.year, now.month, now.day);
        final DateTime end = start.add(const Duration(days: 1));
        return DateTimeRange(start: start, end: end);
      case 'week':
        final int weekday = now.weekday; // 1=Mon .. 7=Sun
        final DateTime start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekday - 1));
        final DateTime end = start.add(const Duration(days: 7));
        return DateTimeRange(start: start, end: end);
      case 'month':
        final DateTime start = DateTime(now.year, now.month);
        final DateTime end = DateTime(now.year, now.month + 1);
        return DateTimeRange(start: start, end: end);
      case 'year':
        final DateTime start = DateTime(now.year);
        final DateTime end = DateTime(now.year + 1);
        return DateTimeRange(start: start, end: end);
      case 'all':
      default:
        return null; // sin filtros
    }
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    final bool isPositive = balance >= 0;
    return Center(
      child: Card(
        color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Text('Balance', style: Theme.of(context).textTheme.titleLarge),
              AnimatedCounter(
                value: balance,
                prefix: '\$',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeExpensesCard extends StatelessWidget {
  const _IncomeExpensesCard({required this.ingresos, required this.gastos});

  final double ingresos;
  final double gastos;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Text(
                  'Ingresos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                AnimatedCounter(
                  value: ingresos,
                  prefix: '\$',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Expanded(
        child: Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Text('Gastos', style: Theme.of(context).textTheme.titleMedium),
                AnimatedCounter(
                  value: gastos,
                  prefix: '\$',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
