import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/core/presentation/widgets/premium_background.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';
import 'package:personal_finance/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:personal_finance/utils/theme.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';
import 'package:personal_finance/utils/widgets/loading_widget.dart';

class ServiceConsultationPage extends StatefulWidget {
  const ServiceConsultationPage({super.key});

  @override
  State<ServiceConsultationPage> createState() =>
      _ServiceConsultationPageState();
}

class _ServiceConsultationPageState extends State<ServiceConsultationPage> {
  @override
  void initState() {
    super.initState();
    // Asegurarse de cargar los presupuestos al entrar
    context.read<BudgetsBloc>().add(BudgetsLoad());
  }

  IconData _getServiceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('luz') || n.contains('electricidad') || n.contains('cfe')) {
      return Icons.lightbulb_outline;
    }
    if (n.contains('agua')) return Icons.water_drop_outlined;
    if (n.contains('internet') ||
        n.contains('wifi') ||
        n.contains('telmex') ||
        n.contains('totalplay')) {
      return Icons.wifi;
    }
    if (n.contains('teléfono') ||
        n.contains('celular') ||
        n.contains('telcel') ||
        n.contains('att')) {
      return Icons.phone_android;
    }
    if (n.contains('gas')) return Icons.local_fire_department_outlined;
    if (n.contains('netflix') ||
        n.contains('streaming') ||
        n.contains('disney') ||
        n.contains('spotify')) {
      return Icons.movie_outlined;
    }
    if (n.contains('renta') || n.contains('alquiler') || n.contains('casa')) {
      return Icons.home_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  Color _getServiceColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('luz') || n.contains('electricidad')) return Colors.amber;
    if (n.contains('agua')) return Colors.blue;
    if (n.contains('internet') || n.contains('wifi')) return Colors.cyan;
    if (n.contains('teléfono') || n.contains('celular')) return Colors.purple;
    if (n.contains('gas')) return Colors.orange;
    if (n.contains('netflix') || n.contains('streaming')) return Colors.red;
    if (n.contains('renta') || n.contains('alquiler')) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final FinanceColors colors = Theme.of(context).extension<FinanceColors>()!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis Servicios',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestiona tus pagos recurrentes desde Firebase',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: BlocBuilder<BudgetsBloc, BudgetsState>(
                  builder: (context, state) {
                    if (state.loading && state.items.isEmpty) {
                      return const Center(child: AppLoadingWidget());
                    }

                    if (state.error != null && state.items.isEmpty) {
                      return Center(child: Text('Error: ${state.error}'));
                    }

                    if (state.items.isEmpty) {
                      return EmptyState(
                        title: 'No hay servicios',
                        message:
                            'Agrega un servicio para llevar el control de tus pagos.',
                        action: IconButton.filledTonal(
                          onPressed: () => _openAddServiceDialog(context),
                          icon: const Icon(Icons.add),
                        ),
                      );
                    }

                    final totalAmount = state.items.fold<double>(
                      0,
                      (sum, item) => sum + item.montoAsDouble,
                    );

                    return RefreshIndicator(
                      onRefresh:
                          () async =>
                              context.read<BudgetsBloc>().add(BudgetsLoad()),
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Status Summary Header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              child: _buildStatusCard(context, totalAmount),
                            ),
                          ),

                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                'Lista de Servicios',
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
                                final budget = state.items[index];
                                return _buildServiceItem(
                                  context,
                                  budget,
                                  colors,
                                );
                              }, childCount: state.items.length),
                            ),
                          ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 80),
                          ), // Space for FAB
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddServiceDialog(context),
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Agregar Servicio'),
      ),
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    Budget budget,
    FinanceColors colors,
  ) {
    final icon = _getServiceIcon(budget.nombre);
    final color = _getServiceColor(budget.nombre);
    final isOverdue = budget.fechaFin.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.glassBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.glassBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          budget.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Vence: ${DateFormat.yMMMd().format(budget.fechaFin)}',
          style: TextStyle(
            color:
                isOverdue
                    ? Colors.redAccent
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 13,
            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${double.tryParse(budget.montoTotal)?.toStringAsFixed(2) ?? "0.00"}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
        onTap: () => _openAddServiceDialog(context, budget: budget),
        onLongPress: () => _confirmDelete(context, budget),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 32,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Firebase Sync',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Presupuesto Total en Servicios',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddServiceDialog(
    BuildContext context, {
    Budget? budget,
  }) async {
    final parentBloc = context.read<BudgetsBloc>();
    final key = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: budget?.nombre ?? '');
    final amountCtrl = TextEditingController(text: budget?.montoTotal ?? '');
    DateTime start = budget?.fechaInicio ?? DateTime.now();
    DateTime end =
        budget?.fechaFin ?? DateTime.now().add(const Duration(days: 30));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    top: 24,
                    left: 24,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: key,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget == null
                                ? 'Nuevo Servicio'
                                : 'Editar Servicio',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nombre del Servicio',
                              prefixIcon: const Icon(Icons.label_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Monto a Presupuestar',
                              prefixIcon: const Icon(Icons.attach_money),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            validator:
                                (v) =>
                                    (double.tryParse(v ?? '') ?? 0) <= 0
                                        ? 'Monto inválido'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: const Text(
                                    'Inicio',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  subtitle: Text(
                                    DateFormat.yMMMd().format(start),
                                  ),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: start,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (d != null) setState(() => start = d);
                                  },
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: const Text(
                                    'Vencimiento',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  subtitle: Text(
                                    DateFormat.yMMMd().format(end),
                                  ),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: end,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (d != null) setState(() => end = d);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                if (!key.currentState!.validate()) return;
                                final payload = Budget(
                                  id: budget?.id,
                                  nombre: nameCtrl.text.trim(),
                                  montoTotal: amountCtrl.text.trim(),
                                  fechaInicio: start,
                                  fechaFin: end,
                                );
                                if (budget == null) {
                                  parentBloc.add(BudgetCreate(payload));
                                } else {
                                  parentBloc.add(BudgetUpdate(payload));
                                }
                                Navigator.pop(context);
                              },
                              child: const Text('Guardar'),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Budget budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar Servicio'),
            content: Text(
              '¿Deseas eliminar "${budget.nombre}" de tus presupuestos?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      context.read<BudgetsBloc>().add(BudgetDelete(budget.id!));
    }
  }
}
