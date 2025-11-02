import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/goals/presentation/bloc/goals_bloc.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/widgets/error_widget.dart' as ew;
import 'package:personal_finance/utils/widgets/loading_widget.dart';

class GoalsCrudPage extends StatelessWidget {
  const GoalsCrudPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<GoalsBloc>(
        create: (_) => GoalsBloc(getIt<GoalRepository>())..add(GoalsLoad()),
        child: const _GoalsView(),
      );
}

class _GoalsView extends StatelessWidget {
  const _GoalsView();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Metas')),
        body: BlocBuilder<GoalsBloc, GoalsState>(
          builder: (BuildContext context, GoalsState state) {
            if (state.loading && state.items.isEmpty) {
              return const Center(child: AppLoadingWidget());
            }
            if (state.error != null && state.items.isEmpty) {
              return Center(child: ew.AppErrorWidget(message: state.error!));
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<GoalsBloc>().add(GoalsLoad()),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: state.items.length,
                itemBuilder: (BuildContext context, int i) {
                  final Goal g = state.items[i];
                  final double progress = g.objetivoAsDouble == 0
                      ? 0
                      : g.actualAsDouble / g.objetivoAsDouble;
                  return Dismissible(
                    key: ValueKey<int?>(g.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) => _confirmDelete(context),
                    onDismissed: (_) => context.read<GoalsBloc>().add(GoalDelete(g.id!)),
                    child: ListTile(
                      leading: const Icon(Icons.flag),
                      title: Text(g.nombre),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('\$${g.actualAsDouble.toStringAsFixed(0)} / \$${g.objetivoAsDouble.toStringAsFixed(0)}'),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: progress),
                        ],
                      ),
                      trailing: Text(_fmt(g.fechaLimite)),
                      onTap: () => _openDialog(context, goal: g),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openDialog(context),
          label: const Text('Nueva meta'),
          icon: const Icon(Icons.add),
        ),
      );

  Future<void> _openDialog(BuildContext context, {Goal? goal}) async {
    final GlobalKey<FormState> key = GlobalKey<FormState>();
    final TextEditingController nameCtrl =
        TextEditingController(text: goal?.nombre ?? '');
    final TextEditingController targetCtrl = TextEditingController(
      text: goal?.objetivoAsDouble.toStringAsFixed(2) ?? '',
    );
    final TextEditingController currentCtrl = TextEditingController(
      text: goal?.actualAsDouble.toStringAsFixed(2) ?? '0',
    );
    final TextEditingController iconCtrl =
        TextEditingController(text: goal?.icono ?? 'flag');
    DateTime limit =
        goal?.fechaLimite ?? DateTime.now().add(const Duration(days: 90));

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(goal == null ? 'Crear meta' : 'Editar meta'),
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
                  validator: (String? v) =>
                      v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: targetCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Monto objetivo'),
                  validator: (String? v) =>
                      (double.tryParse(v ?? '') ?? -1) <= 0
                          ? 'Ingresa un monto válido'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: currentCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Monto actual'),
                  validator: (String? v) =>
                      (double.tryParse(v ?? '') ?? -1) < 0
                          ? 'Monto inválido'
                          : null,
                ),
                const SizedBox(height: 12),
                _DateTile(
                  label: 'Fecha límite',
                  value: limit,
                  onPick: (DateTime d) => limit = d,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: iconCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Icono (nombre Material, ej. flag, star)',
                  ),
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
            onPressed: () {
              if (!key.currentState!.validate()) return;
              final GoalsBloc bloc = context.read<GoalsBloc>();
              final Goal payload = Goal(
                id: goal?.id,
                nombre: nameCtrl.text.trim(),
                montoObjetivo:
                    (double.parse(targetCtrl.text.trim())).toString(),
                montoActual:
                    (double.parse(currentCtrl.text.trim())).toString(),
                fechaLimite: limit,
                icono: iconCtrl.text.trim(),
              );
              if (goal == null) {
                bloc.add(GoalCreate(payload));
              } else {
                bloc.add(GoalUpdate(payload));
              }
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(goal == null ? 'Meta creada' : 'Meta actualizada'),
        ),
      );
    }
  }
}

Future<bool> _confirmDelete(BuildContext context) async {
  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Eliminar meta'),
      content: const Text('¿Deseas eliminar esta meta?'),
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

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.date_range, size: 18),
                  const SizedBox(width: 8),
                  Text(_fmt(value)),
                ],
              ),
            ),
          ),
        ],
      );
}

