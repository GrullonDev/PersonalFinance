import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/goals/presentation/bloc/goals_bloc.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';
import 'package:personal_finance/utils/widgets/error_widget.dart' as ew;
import 'package:personal_finance/utils/widgets/loading_widget.dart';

Future<bool> _confirmDelete(BuildContext context) async {
  final bool? confirm = await showDialog<bool>(
    context: context,
    builder:
        (BuildContext context) => AlertDialog(
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

// Helpers for icon picking/rendering
IconData _iconFromName(String name) {
  const Map<String, IconData> map = <String, IconData>{
    'flag': Icons.flag,
    'star': Icons.star,
    'savings': Icons.savings,
    'home': Icons.home,
    'car': Icons.directions_car,
    'school': Icons.school,
    'favorite': Icons.favorite,
    'flight': Icons.flight_takeoff,
    'shopping': Icons.shopping_cart,
    'health': Icons.health_and_safety,
    'fitness': Icons.fitness_center,
    'restaurant': Icons.restaurant,
    'trophy': Icons.emoji_events,
    'gift': Icons.card_giftcard,
    'beach': Icons.beach_access,
  };
  return map[name.trim().toLowerCase()] ?? Icons.flag;
}

Future<String?> _pickIcon(BuildContext context, String current) async {
  final List<MapEntry<String, IconData>> options = <MapEntry<String, IconData>>[
    const MapEntry<String, IconData>('flag', Icons.flag),
    const MapEntry<String, IconData>('star', Icons.star),
    const MapEntry<String, IconData>('savings', Icons.savings),
    const MapEntry<String, IconData>('home', Icons.home),
    const MapEntry<String, IconData>('car', Icons.directions_car),
    const MapEntry<String, IconData>('school', Icons.school),
    const MapEntry<String, IconData>('favorite', Icons.favorite),
    const MapEntry<String, IconData>('flight', Icons.flight_takeoff),
    const MapEntry<String, IconData>('shopping', Icons.shopping_cart),
    const MapEntry<String, IconData>('health', Icons.health_and_safety),
    const MapEntry<String, IconData>('fitness', Icons.fitness_center),
    const MapEntry<String, IconData>('restaurant', Icons.restaurant),
    const MapEntry<String, IconData>('trophy', Icons.emoji_events),
    const MapEntry<String, IconData>('gift', Icons.card_giftcard),
    const MapEntry<String, IconData>('beach', Icons.beach_access),
  ];

  return showModalBottomSheet<String>(
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
                  'Elige un icono',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                    itemCount: options.length,
                    itemBuilder: (BuildContext _, int i) {
                      final String key = options[i].key;
                      final IconData icon = options[i].value;
                      final bool selected = key == current;
                      return InkWell(
                        onTap: () => Navigator.pop<String>(ctx, key),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? Theme.of(
                                      ctx,
                                    ).colorScheme.primary.withValues(alpha: 0.1)
                                    : Theme.of(ctx).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  selected
                                      ? Theme.of(ctx).colorScheme.primary
                                      : Theme.of(ctx).dividerColor,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

class GoalsCrudPage extends StatelessWidget {
  final bool showAppBar;

  const GoalsCrudPage({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) => BlocProvider<GoalsBloc>(
    create: (_) => GoalsBloc(getIt<GoalRepository>())..add(GoalsLoad()),
    child: _GoalsView(showAppBar: showAppBar),
  );
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
              Text(_fmt(value)),
            ],
          ),
        ),
      ),
    ],
  );
}

class _GoalsView extends StatelessWidget {
  final bool showAppBar;

  const _GoalsView({required this.showAppBar});

  @override
  Widget build(BuildContext context) => Scaffold(
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
                    Icon(Icons.flag_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Metas',
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
                  'Alcanza tus objetivos',
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
    body: BlocBuilder<GoalsBloc, GoalsState>(
      builder: (BuildContext context, GoalsState state) {
        if (state.loading && state.items.isEmpty) {
          return const Center(child: AppLoadingWidget());
        }
        if (state.error != null && state.items.isEmpty) {
          return Center(child: ew.AppErrorWidget(message: state.error!));
        }
        if (state.items.isEmpty) {
          return const EmptyState(
            title: 'Sin metas',
            message: 'Crea tu primera meta para comenzar a ahorrar.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => context.read<GoalsBloc>().add(GoalsLoad()),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: state.items.length,
            itemBuilder: (BuildContext context, int i) {
              final Goal g = state.items[i];
              final double progress =
                  g.objetivoAsDouble == 0
                      ? 0
                      : g.actualAsDouble / g.objetivoAsDouble;
              return Dismissible(
                key: ValueKey<String?>(g.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed:
                    (_) => context.read<GoalsBloc>().add(GoalDelete(g.id!)),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  color:
                      g.actualAsDouble >= g.objetivoAsDouble
                          ? Colors.green.shade50
                          : null,
                  child: InkWell(
                    onTap: () => _openDialog(context, goal: g),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                _iconFromName(g.icono ?? 'flag'),
                                size: 28,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      g.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Meta: ${_fmt(g.fechaLimite)}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (g.actualAsDouble >= g.objetivoAsDouble)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                '\$${g.actualAsDouble.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${g.objetivoAsDouble.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0, end: progress),
                            builder:
                                (BuildContext _, double v, Widget? __) =>
                                    LinearProgressIndicator(
                                      value: v,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
    // Capturar el bloc del contexto padre antes de abrir el diálogo
    final GoalsBloc parentBloc = context.read<GoalsBloc>();
    final GlobalKey<FormState> key = GlobalKey<FormState>();
    final TextEditingController nameCtrl = TextEditingController(
      text: goal?.nombre ?? '',
    );
    final TextEditingController targetCtrl = TextEditingController(
      text: goal?.objetivoAsDouble.toStringAsFixed(2) ?? '',
    );
    final TextEditingController currentCtrl = TextEditingController(
      text: goal?.actualAsDouble.toStringAsFixed(2) ?? '0',
    );
    final TextEditingController iconCtrl = TextEditingController(
      text: goal?.icono ?? 'flag',
    );
    DateTime limit =
        goal?.fechaLimite ?? DateTime.now().add(const Duration(days: 90));

    final bool? saved = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
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
                      validator:
                          (String? v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Ingresa un nombre'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: targetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto objetivo',
                      ),
                      validator:
                          (String? v) =>
                              (double.tryParse(v ?? '') ?? -1) <= 0
                                  ? 'Ingresa un monto válido'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: currentCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto actual',
                      ),
                      validator:
                          (String? v) =>
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: iconCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Icono (nombre Material)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () async {
                            final String? picked = await _pickIcon(
                              context,
                              iconCtrl.text,
                            );
                            if (picked != null) {
                              iconCtrl.text = picked;
                            }
                          },
                          icon: const Icon(Icons.collections),
                          tooltip: 'Elegir icono',
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
                onPressed: () {
                  if (!key.currentState!.validate()) return;
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
                    parentBloc.add(GoalCreate(payload));
                  } else {
                    parentBloc.add(GoalUpdate(payload));
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
          content: Text(goal == null ? 'Meta creada' : 'Meta actualizada'),
        ),
      );
    }
  }
}
