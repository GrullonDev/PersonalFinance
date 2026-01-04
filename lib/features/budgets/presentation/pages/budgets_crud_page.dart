import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';
import 'package:personal_finance/features/budgets/domain/repositories/budget_repository.dart';
import 'package:personal_finance/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:personal_finance/features/categories/domain/entities/category.dart'
    as cat_entity;
import 'package:personal_finance/features/categories/presentation/bloc/categories_bloc.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart'
    as tx_backend;
import 'package:personal_finance/utils/budget_category_prefs.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/theme.dart';
import 'package:personal_finance/utils/responsive.dart';
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
        preferredSize: Size.fromHeight(context.isMobile ? 120 : 100),
        child: _buildAppBar(context),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: context.isMobile ? double.infinity : 1000,
          ),
          child: BlocBuilder<BudgetsBloc, BudgetsState>(
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

              // Use GridView for larger screens, ListView for mobile
              if (!context.isMobile) {
                return RefreshIndicator(
                  onRefresh:
                      () async =>
                          context.read<BudgetsBloc>().add(BudgetsLoad()),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500,
                          mainAxisExtent: 220,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                    itemCount: state.items.length,
                    itemBuilder: (context, i) {
                      final b = state.items[i];
                      return _BudgetCard(budget: b);
                    },
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh:
                    () async => context.read<BudgetsBloc>().add(BudgetsLoad()),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.items.length,
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
                          (_) => context.read<BudgetsBloc>().add(
                            BudgetDelete(b.id!),
                          ),
                      child: _BudgetCard(budget: b),
                    );
                  },
                  separatorBuilder: (_, _) => const Divider(height: 1),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton:
          context.isMobile
              ? Builder(
                builder:
                    (BuildContext context) => FloatingActionButton.extended(
                      onPressed: () => _openDialog(context),
                      label: const Text('Nuevo presupuesto'),
                      icon: const Icon(Icons.add),
                    ),
              )
              : null,
    ),
  );

  Widget _buildAppBar(BuildContext context) {
    return Container(
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Presupuestos',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
              if (!context.isMobile)
                FilledButton.icon(
                  onPressed: () => _openDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo presupuesto'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Eliminar presupuesto'),
            content: const Text('¿Deseas eliminar este presupuesto?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D55).withOpacity(0.1),
                  foregroundColor: const Color(0xFFFF2D55),
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    return confirm ?? false;
  }

  Future<void> _openDialog(BuildContext context, {Budget? budget}) async {
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
          (BuildContext context) => StatefulBuilder(
            builder:
                (BuildContext context, StateSetter setState) => AlertDialog(
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
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                            ),
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
                                  onPick: (DateTime d) {
                                    setState(() => start = d);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _DateTile(
                                  label: 'Fin',
                                  value: end,
                                  onPick: (DateTime d) {
                                    setState(() => end = d);
                                  },
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
          ),
    );

    if (saved == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              budget == null ? 'Presupuesto creado' : 'Presupuesto actualizado',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    final FinanceColors colors = Theme.of(context).extension<FinanceColors>()!;

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

        final CategoriesState catsState = context.watch<CategoriesBloc>().state;

        return Container(
          decoration: BoxDecoration(
            color: colors.glassBackground, // Glassmorphism background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openBudgetDialog(context),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Header: Icon + Name + Percentage + Edit Button
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.pie_chart_outline_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.budget.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              range,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(progress * 100).clamp(0, 999).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color:
                                  over
                                      ? const Color(0xFFFF2D55)
                                      : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          InkWell(
                            onTap: _assignCategories,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.isNaN ? 0.0 : progress,
                          minHeight: 10,
                          backgroundColor:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          color:
                              over
                                  ? const Color(0xFFFF2D55)
                                  : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Gastado: \$${spent.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Total: \$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Categories
                  if (_categoryIds.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Categorías monitoreadas:',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _categoryIds.map((String id) {
                            final String name =
                                catsState.items
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
                            return Chip(
                              label: Text(
                                name,
                                style: const TextStyle(fontSize: 11),
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.5),
                              side: BorderSide.none,
                              deleteIcon: const Icon(Icons.close, size: 14),
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
    final Set<String> selected = _categoryIds.toSet();
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (BuildContext ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Asignar categorías',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children:
                          context
                              .read<CategoriesBloc>()
                              .state
                              .items
                              .map(
                                (cat_entity.Category c) => CheckboxListTile(
                                  value: selected.contains(c.id),
                                  title: Text(c.nombre),
                                  secondary: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (c.tipo.toLowerCase() == 'ingreso'
                                              ? Colors.green
                                              : Colors.red)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      c.tipo.toLowerCase() == 'ingreso'
                                          ? Icons.trending_up
                                          : Icons.trending_down,
                                      color:
                                          c.tipo.toLowerCase() == 'ingreso'
                                              ? Colors.green
                                              : Colors.red,
                                      size: 18,
                                    ),
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Guardar Cambios'),
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

  String _fmt2(DateTime d) => '${d.day}/${d.month}';

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
          (BuildContext context) => StatefulBuilder(
            builder:
                (BuildContext context, StateSetter setState) => AlertDialog(
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
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                            ),
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
                                  onPick: (DateTime d) {
                                    setState(() => start = d);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _DateTile(
                                  label: 'Fin',
                                  value: end,
                                  onPick: (DateTime d) {
                                    setState(() => end = d);
                                  },
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
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (BuildContext context, Widget? child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Theme.of(context).primaryColor,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) onPick(picked);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${value.day}/${value.month}/${value.year}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
