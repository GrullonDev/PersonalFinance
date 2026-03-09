import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';
import 'package:personal_finance/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:personal_finance/utils/currency_helper.dart';
import 'package:personal_finance/utils/premium_modals.dart';
import 'package:personal_finance/utils/theme.dart';
import 'package:personal_finance/utils/responsive.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';
import 'package:personal_finance/utils/widgets/loading_widget.dart';
import 'package:personal_finance/core/services/device_service.dart';
import 'package:personal_finance/utils/injection_container.dart';

class ServiceConsultationPage extends StatefulWidget {
  const ServiceConsultationPage({super.key});

  @override
  State<ServiceConsultationPage> createState() =>
      _ServiceConsultationPageState();

  static Future<void> showAddServiceDialog(
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
    String frecuencia = 'Mensual';

    await showPremiumBottomSheet<void>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => SafeArea(
                  bottom: false,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: context.isMobile ? double.infinity : 500,
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.bolt_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        budget == null
                                            ? 'Agregar Servicio'
                                            : 'Editar Servicio',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Gestiona pagos recurrentes',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                filled: true,
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                              ),
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Requerido'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: amountCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: 'Monto Total',
                                      prefixIcon: const Icon(
                                        Icons.attach_money,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Requerido';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Inválido';
                                      }
                                      if (double.parse(value) <= 0) {
                                        return 'Monto inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: frecuencia,
                                    decoration: InputDecoration(
                                      labelText: 'Frecuencia',
                                      prefixIcon: const Icon(
                                        Icons.autorenew_rounded,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Mensual',
                                        child: Text('Mensual'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Anual',
                                        child: Text('Anual'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => frecuencia = val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final d = await showDatePicker(
                                        context: context,
                                        initialDate: start,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (d != null) setState(() => start = d);
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Inicio',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                DateFormat.yMMMd().format(
                                                  start,
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final d = await showDatePicker(
                                        context: context,
                                        initialDate: end,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (d != null) setState(() => end = d);
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Vencimiento',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.event_available,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                DateFormat.yMMMd().format(end),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      foregroundColor: Colors.grey.shade600,
                                    ),
                                    child: const Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                    ),
                                    onPressed: () {
                                      if (!key.currentState!.validate()) return;
                                      final now = DateTime.now();
                                      final deviceId =
                                          getIt<DeviceService>().deviceId;
                                      final payload = Budget(
                                        id:
                                            budget?.id ??
                                            'service_${now.microsecondsSinceEpoch}',
                                        createdAt: budget?.createdAt ?? now,
                                        updatedAt: now,
                                        deviceId: budget?.deviceId ?? deviceId,
                                        version: (budget?.version ?? 0) + 1,
                                        nombre:
                                            '${nameCtrl.text.trim()} ($frecuencia)',
                                        montoTotal: amountCtrl.text.trim(),
                                        fechaInicio: start,
                                        fechaFin: end,
                                      );
                                      if (budget == null) {
                                        parentBloc.add(BudgetCreate(payload));
                                      } else {
                                        parentBloc.add(BudgetUpdate(payload));
                                      }
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      budget == null
                                          ? 'Guardar Servicio'
                                          : 'Actualizar',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
    );
  }
}

class _ServiceConsultationPageState extends State<ServiceConsultationPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Asegurarse de cargar los presupuestos al entrar
    context.read<BudgetsBloc>().add(BudgetsLoad());

  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            'Gestiona tus pagos recurrentes',
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
                        onPressed: () => ServiceConsultationPage.showAddServiceDialog(context),
                        icon: const Icon(Icons.add_card_rounded),
                        label: const Text('Agregar Servicio'),
                      ),
                  ],
                ),
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
                        onPressed: () => ServiceConsultationPage.showAddServiceDialog(context),
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
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: context.isMobile ? double.infinity : 1000,
                        ),
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            // Status Summary Header
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 24,
                                  left: 20,
                                  right: 20,
                                ),
                                child: _buildStatusCard(context, totalAmount),
                              ),
                            ),

                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: Text(
                                  'Lista de Servicios',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 16),
                            ),

                            if (context.isMobile)
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
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
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 450,
                                        mainAxisExtent: 100,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
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
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          budget.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOverdue)
              const Text(
                'Pago pendiente',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              isOverdue
                  ? 'Vencido hace ${DateTime.now().difference(budget.fechaFin).inDays} días 🔴'
                  : 'Vence en ${budget.fechaFin.difference(DateTime.now()).inDays} días',
              style: TextStyle(
                color:
                    isOverdue
                        ? Colors.redAccent
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${CurrencyHelper.symbol}${double.tryParse(budget.montoTotal)?.toStringAsFixed(2) ?? "0.00"}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
        onTap: () => ServiceConsultationPage.showAddServiceDialog(context, budget: budget),
        onLongPress: () => _confirmDelete(context, budget),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, double total) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
            const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 32,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
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
          'Total: ${CurrencyHelper.symbol}${total.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );


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
      context.read<BudgetsBloc>().add(BudgetDelete(budget.id));
    }
  }
}
