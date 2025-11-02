import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:personal_finance/features/budgets/domain/entities/budget.dart';
import 'package:personal_finance/features/budgets/domain/repositories/budget_repository.dart';
import 'package:personal_finance/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/widgets/error_widget.dart' as ew;
import 'package:personal_finance/utils/widgets/loading_widget.dart';

class BudgetsCrudPage extends StatelessWidget {
  const BudgetsCrudPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<BudgetsBloc>(
        create: (_) => BudgetsBloc(getIt<BudgetRepository>())..add(BudgetsLoad()),
        child: Scaffold(
          appBar: AppBar(title: const Text('Presupuestos')),
          body: BlocBuilder<BudgetsBloc, BudgetsState>(
            builder: (BuildContext context, BudgetsState state) {
              if (state.loading && state.items.isEmpty) {
                return const Center(child: AppLoadingWidget());
              }
              if (state.error != null && state.items.isEmpty) {
                return Center(child: ew.AppErrorWidget(message: state.error!));
              }
              return RefreshIndicator(
                onRefresh: () async => context.read<BudgetsBloc>().add(BudgetsLoad()),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.items.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (BuildContext context, int i) {
                    final Budget b = state.items[i];
                    final String range = '${_fmt(b.fechaInicio)} → ${_fmt(b.fechaFin)}';
                    return Dismissible(
                      key: ValueKey<int?>(b.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) => _confirmDelete(context),
                      onDismissed: (_) => context.read<BudgetsBloc>().add(BudgetDelete(b.id!)),
                      child: ListTile(
                        leading: const Icon(Icons.pie_chart),
                        title: Text(b.nombre),
                        subtitle: Text(range),
                        trailing: Text('\$${b.montoAsDouble.toStringAsFixed(2)}'),
                        onTap: () => _openDialog(context, budget: b),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                ),
              );
            },
          ),
          floatingActionButton: Builder(
            builder: (BuildContext context) => FloatingActionButton.extended(
              onPressed: () => _openDialog(context),
              label: const Text('Nuevo presupuesto'),
              icon: const Icon(Icons.add),
            ),
          ),
        ),
      );

  Future<void> _openDialog(BuildContext context, {Budget? budget}) async {
    final GlobalKey<FormState> key = GlobalKey<FormState>();
    final TextEditingController nameCtrl = TextEditingController(text: budget?.nombre ?? '');
    final TextEditingController amountCtrl = TextEditingController(text: budget?.montoAsDouble.toStringAsFixed(2) ?? '');
    DateTime start = budget?.fechaInicio ?? DateTime.now();
    DateTime end = budget?.fechaFin ?? DateTime.now().add(const Duration(days: 30));

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(budget == null ? 'Crear presupuesto' : 'Editar presupuesto'),
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
                  validator: (String? v) => v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto total'),
                  validator: (String? v) => (double.tryParse(v ?? '') ?? -1) <= 0 ? 'Ingresa un monto válido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(child: _DateTile(label: 'Inicio', value: start, onPick: (DateTime d) => start = d)),
                    const SizedBox(width: 8),
                    Expanded(child: _DateTile(label: 'Fin', value: end, onPick: (DateTime d) => end = d)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              final BudgetsBloc bloc = context.read<BudgetsBloc>();
              final Budget payload = Budget(
                id: budget?.id,
                nombre: nameCtrl.text.trim(),
                montoTotal: (double.parse(amountCtrl.text.trim())).toString(),
                fechaInicio: start,
                fechaFin: end,
              );
              if (budget == null) {
                bloc.add(BudgetCreate(payload));
              } else {
                bloc.add(BudgetUpdate(payload));
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
        SnackBar(content: Text(budget == null ? 'Presupuesto creado' : 'Presupuesto actualizado')),
      );
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar presupuesto'),
        content: const Text('¿Deseas eliminar este presupuesto?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    return confirm ?? false;
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onPick});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

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
                  Text('${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'),
                ],
              ),
            ),
          ),
        ],
      );
}
