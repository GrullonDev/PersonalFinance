import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import 'package:personal_finance/core/utils/input_sanitizer.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/presentation/bloc/goals_bloc.dart';
import 'package:personal_finance/utils/currency_helper.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/core/services/transaction_linking_service.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';
import 'package:personal_finance/utils/widgets/error_widget.dart' as ew;
import 'package:personal_finance/utils/widgets/loading_widget.dart';
import 'package:personal_finance/features/subscription/domain/services/subscription_service.dart';
import 'package:personal_finance/features/subscription/presentation/pages/paywall_page.dart';

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

String _fmtReadable(DateTime d) {
  const List<String> months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${d.day} ${months[d.month - 1]}. ${d.year}';
}

const List<String> _kPresetLabels = <String>[
  '1 mes',
  '3 meses',
  '6 meses',
  '1 año',
  '2 años',
];
const List<int> _kPresetDays = <int>[30, 90, 180, 365, 730];

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
  Widget build(BuildContext context) => BlocProvider<GoalsBloc>.value(
    value: getIt<GoalsBloc>()..add(GoalsLoad()),
    child: _GoalsView(showAppBar: showAppBar),
  );
}

class _GoalsView extends StatefulWidget {
  final bool showAppBar;

  const _GoalsView({required this.showAppBar});

  @override
  State<_GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<_GoalsView> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                        color: Colors.white.withValues(alpha: 0.9),
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
                        (_) => context.read<GoalsBloc>().add(GoalDelete(g.id ?? '')),
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          'Meta: ${_fmtReadable(g.fechaLimite)}',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    '${CurrencyHelper.symbol}${g.actualAsDouble.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${CurrencyHelper.symbol}${g.objetivoAsDouble.toStringAsFixed(0)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
          heroTag: null,
          onPressed: () => _openDialog(context),
          label: const Text('Nueva meta'),
          icon: const Icon(Icons.add),
        ),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: 3.14 / 2, // Default: downwards
          blastDirectionality: BlastDirectionality.explosive,
          minBlastForce: 8, // set a lower min blast force
          emissionFrequency: 0.05,
          numberOfParticles: 50, // a reasonable number
          gravity: 0.1,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple,
          ], // manually specify the colors to be used
        ),
      ),
    ],
  );

  Future<void> _openDialog(BuildContext context, {Goal? goal}) async {
    // Feature gate: solo se comprueba al crear, no al editar.
    if (goal == null) {
      final subscriptionService = getIt<SubscriptionService>();
      final currentCount = context.read<GoalsBloc>().state.items.length;
      if (subscriptionService.isAtGoalLimit(currentCount)) {
        await PaywallPage.show(context);
        return;
      }
    }

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
    bool isDetecting = false;
    final TextEditingController iconCtrl = TextEditingController(
      text: goal?.icono ?? 'flag',
    );
    DateTime limit =
        goal?.fechaLimite ?? DateTime.now().add(const Duration(days: 90));
    String? selectedPreset = goal == null ? '3 meses' : null;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dlgCtx) => StatefulBuilder(
            builder: (BuildContext dlgCtx, StateSetter setDialogState) {
              final DateTime now = DateTime.now();
              final int daysLeft = limit.difference(now).inDays;
              return AlertDialog(
                title: Text(goal == null ? 'Crear meta' : 'Editar meta'),
                content: Form(
                  key: key,
                  child: SizedBox(
                    width: 360,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'[<>]')),
                              LengthLimitingTextInputFormatter(120),
                            ],
                            validator:
                                (String? v) =>
                                    InputSanitizer.validateName(v ?? ''),
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
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                              LengthLimitingTextInputFormatter(15),
                            ],
                            validator:
                                (String? v) =>
                                    InputSanitizer.validateAmount(v ?? ''),
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
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                              LengthLimitingTextInputFormatter(15),
                            ],
                            validator: (String? v) {
                              if (v == null || v.isEmpty) return 'Requerido';
                              final val = double.tryParse(v);
                              if (val == null || val < 0) {
                                return 'Monto inválido';
                              }
                              if (val > 999999999) {
                                return 'Monto demasiado grande';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // ── Plazo / duration picker ──────────────────────
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Plazo',
                                style: Theme.of(dlgCtx).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: <Widget>[
                                  for (
                                    int i = 0;
                                    i < _kPresetLabels.length;
                                    i++
                                  )
                                    ChoiceChip(
                                      label: Text(_kPresetLabels[i]),
                                      selected:
                                          selectedPreset == _kPresetLabels[i],
                                      onSelected: (bool v) {
                                        if (!v) return;
                                        setDialogState(() {
                                          selectedPreset = _kPresetLabels[i];
                                          limit = now.add(
                                            Duration(days: _kPresetDays[i]),
                                          );
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      daysLeft > 0
                                          ? '${_fmtReadable(limit)}  ·  $daysLeft días'
                                          : _fmtReadable(limit),
                                      style: Theme.of(
                                        dlgCtx,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            Theme.of(
                                              dlgCtx,
                                            ).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                            context: dlgCtx,
                                            initialDate:
                                                limit.isAfter(now)
                                                    ? limit
                                                    : now.add(
                                                      const Duration(days: 30),
                                                    ),
                                            firstDate: now,
                                            lastDate: now.add(
                                              const Duration(days: 3650),
                                            ),
                                          );
                                      if (picked != null) {
                                        setDialogState(() {
                                          limit = picked;
                                          selectedPreset = null;
                                        });
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.edit_calendar,
                                      size: 16,
                                    ),
                                    label: const Text('Fecha exacta'),
                                  ),
                                ],
                              ),
                            ],
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
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9_\-\.]'),
                                    ),
                                    LengthLimitingTextInputFormatter(50),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Requerido';
                                    }
                                    if (!RegExp(
                                      r'^[a-zA-Z0-9_\-\.]+$',
                                    ).hasMatch(v.trim())) {
                                      return 'Icono inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                onPressed: () async {
                                  final String? picked = await _pickIcon(
                                    dlgCtx,
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
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(dlgCtx, false),
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
                      if (dlgCtx.mounted) Navigator.pop(dlgCtx, true);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          ),
        ),
    );

    if (saved == true && context.mounted) {
      if (goal == null) {
        _confettiController.play();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            goal == null ? '¡Felicidades! Meta creada' : 'Meta actualizada',
          ),
          backgroundColor: goal == null ? Colors.green.shade600 : null,
        ),
      );
    }
  }
}
