import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';
import 'package:personal_finance/features/budgets/domain/repositories/budget_repository.dart';
import 'package:personal_finance/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:personal_finance/features/categories/domain/entities/category.dart'
    as cat_entity;
import 'package:personal_finance/features/categories/presentation/providers/categories_provider.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart'
    as tx_backend;
import 'package:personal_finance/utils/budget_category_prefs.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';
import 'package:personal_finance/utils/widgets/error_widget.dart' as ew;
import 'package:personal_finance/utils/widgets/loading_widget.dart';

class BudgetsCrudPage extends StatelessWidget {
  final bool showAppBar;

  const BudgetsCrudPage({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) => BlocProvider<BudgetsBloc>(
    create: (_) => BudgetsBloc(getIt<BudgetRepository>())..add(BudgetsLoad()),
    child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Presupuestos',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Planifica tus gastos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<BudgetsBloc, BudgetsState>(
        builder: (BuildContext context, BudgetsState state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: AppLoadingWidget());
          }
          if (state.error != null && state.items.isEmpty) {
            return Center(child: ew.AppErrorWidget(message: state.error!));
          }
          if (state.items.isEmpty) {
            return EmptyState(
              title: 'Sin presupuestos',
              message: 'Crea un presupuesto para planear tus gastos.',
              action: FilledButton.icon(
                onPressed: () => _openDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo presupuesto'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh:
                () async => context.read<BudgetsBloc>().add(BudgetsLoad()),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.items.length,
              // Extra espacio inferior para que no colisione con el FAB.
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemBuilder: (BuildContext context, int i) {
                final Budget b = state.items[i];
                return Dismissible(
                  key: ValueKey<String?>(b.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context),
                  onDismissed:
                      (_) =>
                          context.read<BudgetsBloc>().add(BudgetDelete(b.id!)),
                  child: _BudgetCard(budget: b),
                );
              },
              separatorBuilder: (_, _) => const Divider(height: 1),
            ),
          );
        },
      ),
      floatingActionButton: Builder(
        builder:
            (BuildContext context) => FloatingActionButton.extended(
              onPressed: () => _openDialog(context),
              label: const Text('Nuevo presupuesto'),
              icon: const Icon(Icons.add),
            ),
      ),
    ),
  );

  Future<bool> _confirmDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Eliminar presupuesto'),
            content: const Text('¿Deseas eliminar este presupuesto?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    return confirm ?? false;
  }

  Future<void> _openDialog(BuildContext context, {Budget? budget}) async {
    // Captura el bloc con el contexto padre antes de abrir el diálogo
    final BudgetsBloc parentBloc = context.read<BudgetsBloc>();
    final GlobalKey<FormState> key = GlobalKey<FormState>();
    final TextEditingController nameCtrl = TextEditingController(
      text: budget?.nombre ?? '',
    );
    final TextEditingController amountCtrl = TextEditingController(
      text: budget?.montoAsDouble.toStringAsFixed(2) ?? '',
    );
    DateTime start = budget?.fechaInicio ?? DateTime.now();
    DateTime end =
        budget?.fechaFin ?? DateTime.now().add(const Duration(days: 30));

    final bool? saved = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text(
              budget == null ? 'Crear presupuesto' : 'Editar presupuesto',
            ),
            content: Form(
              key: key,
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator:
                          (String? v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Ingresa un nombre'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto total',
                      ),
                      validator:
                          (String? v) =>
                              (double.tryParse(v ?? '') ?? -1) <= 0
                                  ? 'Ingresa un monto válido'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _DateTile(
                            label: 'Inicio',
                            value: start,
                            onPick: (DateTime d) => start = d,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DateTile(
                            label: 'Fin',
                            value: end,
                            onPick: (DateTime d) => end = d,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!key.currentState!.validate()) return;
                  final Budget payload = Budget(
                    id: budget?.id,
                    nombre: nameCtrl.text.trim(),
                    montoTotal:
                        (double.parse(amountCtrl.text.trim())).toString(),
                    fechaInicio: start,
                    fechaFin: end,
                  );
                  if (budget == null) {
                    parentBloc.add(BudgetCreate(payload));
                  } else {
                    parentBloc.add(BudgetUpdate(payload));
                  }
                  if (context.mounted) Navigator.pop(context, true);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            budget == null ? 'Presupuesto creado' : 'Presupuesto actualizado',
          ),
        ),
      );
    }
  }
}

class _BudgetCard extends StatefulWidget {
  final Budget budget;
  const _BudgetCard({required this.budget});

  @override
  State<_BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<_BudgetCard> {
  List<String> _categoryIds = <String>[];

  @override
  Widget build(BuildContext context) {
    final tx_backend.TransactionBackendRepository repo =
        context.read<tx_backend.TransactionBackendRepository>();

    return FutureBuilder<double>(
      future: _spent(repo),
      builder: (BuildContext context, AsyncSnapshot<double> snap) {
        final double spent = snap.data ?? 0.0;
        final double total = widget.budget.montoAsDouble;
        final double progress =
            total <= 0 ? 0.0 : (spent / total).clamp(0.0, 1.0);
        final String range =
            '${_fmt2(widget.budget.fechaInicio)} → ${_fmt2(widget.budget.fechaFin)}';
        final bool over = spent > total && total > 0;

        final CategoriesProvider cats = context.watch<CategoriesProvider>();

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openBudgetDialog(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Header: Icon + Name + Percentage + Edit Button
                  Row(
                    children: <Widget>[
                      const Icon(Icons.pie_chart, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.budget.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).clamp(0, 999).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              over
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Asignar categorías',
                        icon: const Icon(Icons.tune),
                        onPressed: _assignCategories,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Date Range
                  Text(range, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),

                  // Progress Bar
                  LinearProgressIndicator(
                    value: progress.isNaN ? 0.0 : progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    color:
                        over
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),

                  // Amounts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Gastado: \\${spent.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Total: \\${total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Categories
                  if (_categoryIds.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'Categorías asignadas:',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _categoryIds.map((String id) {
                            final String name =
                                cats.categories
                                    .firstWhere(
                                      (cat_entity.Category c) => c.id == id,
                                      orElse:
                                          () => cat_entity.Category(
                                            id: id,
                                            nombre: 'Cat #$id',
                                            tipo: 'gasto',
                                          ),
                                    )
                                    .nombre;
                            return InputChip(
                              label: Text(name),
                              visualDensity: VisualDensity.compact,
                              onDeleted: () async {
                                final List<String> list = List<String>.from(
                                  _categoryIds,
                                )..remove(id);
                                if (widget.budget.id != null) {
                                  await BudgetCategoryPrefs.save(
                                    widget.budget.id!,
                                    list,
                                  );
                                }
                                if (mounted) {
                                  setState(() => _categoryIds = list);
                                }
                              },
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _assignCategories() async {
    if (widget.budget.id == null) return;
    final CategoriesProvider cats = context.read<CategoriesProvider>();
    final Set<String> selected = _categoryIds.toSet();
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder:
          (BuildContext ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Asignar categorías',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children:
                          cats.categories
                              .map(
                                (cat_entity.Category c) => CheckboxListTile(
                                  value: selected.contains(c.id),
                                  title: Text(c.nombre),
                                  secondary: Icon(
                                    c.tipo.toLowerCase() == 'ingreso'
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color:
                                        c.tipo.toLowerCase() == 'ingreso'
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                  onChanged: (bool? v) {
                                    if (v == true) {
                                      selected.add(c.id!);
                                    } else {
                                      selected.remove(c.id);
                                    }
                                    (ctx as Element).markNeedsBuild();
                                  },
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
    if (saved == true) {
      final List<String> list = selected.toList();
      await BudgetCategoryPrefs.save(widget.budget.id!, list);
      if (mounted) setState(() => _categoryIds = list);
    }
  }

  String _fmt2(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadCategories() async {
    if (widget.budget.id != null) {
      final List<String> ids = await BudgetCategoryPrefs.load(
        widget.budget.id!,
      );
      if (mounted) setState(() => _categoryIds = ids);
    }
  }

  Future<void> _openBudgetDialog(BuildContext context) async {
    final BudgetsBloc parentBloc = context.read<BudgetsBloc>();
    final GlobalKey<FormState> key = GlobalKey<FormState>();
    final TextEditingController nameCtrl = TextEditingController(
      text: widget.budget.nombre,
    );
    final TextEditingController amountCtrl = TextEditingController(
      text: widget.budget.montoAsDouble.toStringAsFixed(2),
    );
    DateTime start = widget.budget.fechaInicio;
    DateTime end = widget.budget.fechaFin;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Editar presupuesto'),
            content: Form(
              key: key,
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator:
                          (String? v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Ingresa un nombre'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto total',
                      ),
                      validator:
                          (String? v) =>
                              (double.tryParse(v ?? '') ?? -1) <= 0
                                  ? 'Ingresa un monto válido'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _DateTile(
                            label: 'Inicio',
                            value: start,
                            onPick: (DateTime d) => start = d,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DateTile(
                            label: 'Fin',
                            value: end,
                            onPick: (DateTime d) => end = d,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!key.currentState!.validate()) return;
                  final Budget payload = Budget(
                    id: widget.budget.id,
                    nombre: nameCtrl.text.trim(),
                    montoTotal:
                        (double.parse(amountCtrl.text.trim())).toString(),
                    fechaInicio: start,
                    fechaFin: end,
                  );
                  parentBloc.add(BudgetUpdate(payload));
                  if (context.mounted) Navigator.pop(context, true);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Presupuesto actualizado')));
    }
  }

  Future<double> _spent(tx_backend.TransactionBackendRepository repo) async =>
      _sumGastos(repo, widget.budget.fechaInicio, widget.budget.fechaFin);

  Future<double> _sumGastos(
    tx_backend.TransactionBackendRepository repo,
    DateTime desde,
    DateTime hasta,
  ) async {
    final dartz.Either<Failure, List<TransactionBackend>> res = await repo.list(
      fechaDesde: desde,
      fechaHasta: hasta,
      tipo: 'gasto',
    );
    return res.fold<double>((Failure l) => 0.0, (List<TransactionBackend> r) {
      final List<TransactionBackend> filtered =
          _categoryIds.isEmpty
              ? r
              : r
                  .where(
                    (TransactionBackend e) =>
                        _categoryIds.contains(e.categoriaId),
                  )
                  .toList();
      return filtered.fold<double>(
        0,
        (double a, TransactionBackend e) => a + e.montoAsDouble,
      );
    });
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;
  const _DateTile({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) onPick(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.date_range, size: 18),
              const SizedBox(width: 8),
              Text(
                '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
