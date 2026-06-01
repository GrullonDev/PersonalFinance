import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/core/services/haptic_feedback_service.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/settings/presentation/providers/settings_provider.dart';
import 'package:personal_finance/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:personal_finance/features/subscription/presentation/pages/paywall_page.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_event.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_state.dart';
import 'package:personal_finance/features/quick_finance/presentation/pages/sync_status_page.dart';
import 'package:personal_finance/features/quick_finance/presentation/widgets/balance_card.dart';
import 'package:personal_finance/features/quick_finance/presentation/widgets/quick_entry_input.dart';
import 'package:personal_finance/features/quick_finance/presentation/widgets/transactions_list.dart';

class QuickFinanceHomePage extends StatefulWidget {
  const QuickFinanceHomePage({super.key});

  @override
  State<QuickFinanceHomePage> createState() => _QuickFinanceHomePageState();
}

class _QuickFinanceHomePageState extends State<QuickFinanceHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _syncAnim;
  final _entryKey = GlobalKey<QuickEntryInputState>();

  @override
  void initState() {
    super.initState();

    _syncAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    context.read<QuickFinanceBloc>().add(const WatchDataRequested());

    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      getIt<SubscriptionBloc>().add(SubscriptionLoad(uid));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<QuickFinanceBloc>().state.isSyncing) {
        _syncAnim.repeat();
      }
    });
  }

  @override
  void dispose() {
    _syncAnim.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<QuickFinanceBloc>();
    await HapticFeedbackService.selection();
    bloc.add(const SyncTransactionsRequested());
    await bloc.stream
        .firstWhere((s) => !s.isSyncing)
        .timeout(const Duration(seconds: 15), onTimeout: () => bloc.state);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Seguro que quieres salir?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Salir'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<AuthProvider>().logout();
      } catch (_) {}
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RoutePath.login, (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hideAmounts = context.watch<SettingsProvider>().hideAmounts;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context),
        body: BlocListener<QuickFinanceBloc, QuickFinanceState>(
          listenWhen:
              (prev, curr) =>
                  (curr.status == QuickFinanceStatus.failure &&
                      curr.errorMessage != null &&
                      prev.errorMessage != curr.errorMessage) ||
                  (prev.isSyncing != curr.isSyncing),
          listener: (context, state) {
            if (state.status == QuickFinanceStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  ),
                );
            }

            if (state.isSyncing) {
              _syncAnim.repeat();
            } else {
              _syncAnim
                ..stop()
                ..reset();
            }
          },
          child: BlocBuilder<QuickFinanceBloc, QuickFinanceState>(
            builder: (context, state) {
              if (state.status == QuickFinanceStatus.loading &&
                  state.transactions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return _Body(
                onRefresh: _onRefresh,
                state: state,
                entryKey: _entryKey,
                hideAmounts: hideAmounts,
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firstName = _extractFirstName(auth.currentUser?.fullName);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            firstName != null ? 'Hola, $firstName 👋' : 'Mis finanzas',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            'Tu resumen de hoy',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: _ChatButton(),
      actions: [
        BlocBuilder<QuickFinanceBloc, QuickFinanceState>(
          buildWhen: (prev, curr) => prev.isSyncing != curr.isSyncing,
          builder: (context, state) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: RotationTransition(
                  turns: _syncAnim,
                  child: Icon(
                    Icons.sync_rounded,
                    color: state.isSyncing ? Theme.of(context).primaryColor : null,
                  ),
                ),
                tooltip: state.isSyncing ? 'Sincronizando…' : 'Sincronizar',
                onPressed: state.isSyncing
                    ? null
                    : () => context.read<QuickFinanceBloc>().add(
                          const SyncTransactionsRequested(),
                        ),
              ),
              PopupMenuButton<_MenuAction>(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'Más opciones',
                onSelected: (action) {
                  switch (action) {
                    case _MenuAction.settings:
                      Navigator.of(context).pushNamed(RoutePath.settings);
                    case _MenuAction.logout:
                      _logout();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _MenuAction.settings,
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Configuración'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _MenuAction.logout,
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _extractFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return null;
    return fullName.trim().split(' ').first;
  }
}

enum _MenuAction { settings, logout }

// ── Chat button con gate de suscripción ───────────────────────────────────────

class _ChatButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SubscriptionBloc, SubscriptionState>(
        bloc: getIt<SubscriptionBloc>(),
        builder: (context, state) {
          final isPremium = state.isPremium;
          return IconButton(
            tooltip: isPremium ? 'Asistente Financiero IA' : 'Función Pro',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isPremium ? Icons.chat_rounded : Icons.chat_outlined,
                  color: Theme.of(context).primaryColor,
                  applyTextScaling: true,
                ),
                if (!isPremium)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 6,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              if (isPremium) {
                Navigator.of(context).pushNamed(RoutePath.aiChat);
              } else {
                PaywallPage.show(context);
              }
            },
          );
        },
      );
}

// ── Cuerpo principal ──────────────────────────────────────────────────────────

class _Body extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final QuickFinanceState state;
  final GlobalKey<QuickEntryInputState> entryKey;
  final bool hideAmounts;

  const _Body({
    required this.onRefresh,
    required this.state,
    required this.entryKey,
    required this.hideAmounts,
  });

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _quickStart(String text) {
    widget.entryKey.currentState?.prefill(text);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final insight = _computeInsight(widget.state.transactions);
    final pendingCount =
        widget.state.transactions
            .where(
              (t) => t.syncStatus == SyncStatus.pending && t.deletedAt == null,
            )
            .length;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: Theme.of(context).primaryColor,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: BalanceCard(
                transactions: widget.state.transactions,
                forceHidden: widget.hideAmounts,
              ),
            ),
          ),
          // Sync status — always visible, tappable
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _SyncStatusRow(
                isSyncing: widget.state.isSyncing,
                pendingCount: pendingCount,
                isOffline: widget.state.isOffline,
                hasSyncError: widget.state.syncError != null,
              ),
            ),
          ),
          if (insight != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _InsightBanner(insight: insight),
              ),
            ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
            sliver: SliverToBoxAdapter(child: _QuickActionsRow()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionBadge(
                    label: 'REGISTRAR',
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Entrada rápida',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  QuickEntryInput(
                    key: widget.entryKey,
                    onSubmit: (raw) => context.read<QuickFinanceBloc>().add(
                          RawEntrySubmitted(raw),
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionBadge(
                        label: 'HISTORIAL',
                        color: Theme.of(context).primaryColor,
                      ),
                      if (widget.state.transactions.isNotEmpty)
                        Text(
                          '${widget.state.transactions.length} registros',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Movimientos recientes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverToBoxAdapter(
              child: TransactionsList(
                hideAmounts: widget.hideAmounts,
                transactions: widget.state.transactions,
                onDelete:
                    (id) => context.read<QuickFinanceBloc>().add(
                      DeleteTransactionRequested(id),
                    ),
                onQuickStart: _quickStart,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sync status row ───────────────────────────────────────────────────────────

class _SyncStatusRow extends StatelessWidget {
  final bool isSyncing;
  final int pendingCount;
  final bool isOffline;
  final bool hasSyncError;

  const _SyncStatusRow({
    required this.isSyncing,
    required this.pendingCount,
    required this.isOffline,
    required this.hasSyncError,
  });

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String text, Color color) = _resolve();

    return GestureDetector(
      onTap: () {
        final bloc = context.read<QuickFinanceBloc>();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder:
                (_) => BlocProvider<QuickFinanceBloc>.value(
                  value: bloc,
                  child: const SyncStatusPage(),
                ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Botón "Sincronizar ahora" inline cuando hay pendientes o error
            if (!isSyncing && !isOffline && (pendingCount > 0 || hasSyncError))
              BlocBuilder<QuickFinanceBloc, QuickFinanceState>(
                buildWhen: (p, c) => p.isSyncing != c.isSyncing,
                builder:
                    (context, state) => GestureDetector(
                      onTap:
                          () => context.read<QuickFinanceBloc>().add(
                            const SyncTransactionsRequested(),
                          ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync_rounded, size: 11, color: color),
                            const SizedBox(width: 4),
                            Text(
                              'Sincronizar',
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String, Color) _resolve() {
    if (isSyncing) {
      return (Icons.sync_rounded, 'Sincronizando…', const Color(0xFF007AFF));
    }
    if (isOffline) {
      return (Icons.wifi_off_rounded, 'Sin conexión', const Color(0xFF8E8E93));
    }
    if (hasSyncError) {
      return (
        Icons.cloud_off_rounded,
        'Error al sincronizar',
        const Color(0xFFFF3B30),
      );
    }
    if (pendingCount > 0) {
      return (
        Icons.cloud_upload_outlined,
        pendingCount == 1
            ? '1 movimiento pendiente de sincronizar'
            : '$pendingCount movimientos pendientes de sincronizar',
        const Color(0xFFFF9500),
      );
    }
    return (
      Icons.check_circle_outline_rounded,
      'Sincronizado',
      const Color(0xFF34C759),
    );
  }
}

// ── Quick actions row ─────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        _QuickActionCard(
          icon: Icons.flag_rounded,
          label: 'Metas',
          color: const Color(0xFF34C759),
          onTap: () => Navigator.of(context).pushNamed(RoutePath.goals),
        ),
        const SizedBox(width: 10),
        _QuickActionCard(
          icon: Icons.pie_chart_rounded,
          label: 'Presupuestos',
          color: const Color(0xFF007AFF),
          onTap: () => Navigator.of(context).pushNamed(RoutePath.budgetsCrud),
        ),
        const SizedBox(width: 10),
        _QuickActionCard(
          icon: Icons.credit_card_rounded,
          label: 'Deudas',
          color: const Color(0xFFFF9500),
          onTap: () => Navigator.of(context).pushNamed(RoutePath.debts),
        ),
        const SizedBox(width: 10),
        _QuickActionCard(
          icon: Icons.grid_view_rounded,
          label: 'Categorías',
          color: const Color(0xFF5856D6),
          onTap: () => Navigator.of(context).pushNamed(RoutePath.categories),
        ),
      ],
    ),
  );
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

// ── Section badge (onboarding-style label) ────────────────────────────────────

class _SectionBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.28)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.8,
      ),
    ),
  );
}

// ── Insight banner ────────────────────────────────────────────────────────────

class _InsightBanner extends StatelessWidget {
  final _InsightData insight;
  const _InsightBanner({required this.insight});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: insight.color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: insight.color.withValues(alpha: 0.35),
        width: 1.2,
      ),
    ),
    child: Row(
      children: [
        Icon(insight.icon, size: 15, color: insight.color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            insight.text,
            style: TextStyle(
              fontSize: 13,
              color: insight.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Insight computation ───────────────────────────────────────────────────────

class _InsightData {
  final IconData icon;
  final String text;
  final Color color;
  const _InsightData({
    required this.icon,
    required this.text,
    required this.color,
  });
}

_InsightData? _computeInsight(List<TransactionEntity> transactions) {
  if (transactions.isEmpty) return null;

  final now = DateTime.now();
  final todayHasEntry = transactions.any(
    (t) =>
        t.deletedAt == null &&
        t.createdAt.year == now.year &&
        t.createdAt.month == now.month &&
        t.createdAt.day == now.day,
  );

  if (!todayHasEntry) {
    return const _InsightData(
      icon: Icons.notifications_none_rounded,
      text: 'No has registrado movimientos hoy',
      color: Color(0xFF007AFF),
    );
  }

  // Top expense category this week
  final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final weekExpenses =
      transactions
          .where(
            (t) =>
                t.deletedAt == null &&
                t.type == TransactionType.expense &&
                !t.createdAt.isBefore(weekStart),
          )
          .toList();

  if (weekExpenses.length >= 3) {
    final catAmounts = <String, double>{};
    for (final t in weekExpenses) {
      final cat = _inferCategory(t.note, t.categoryId) ?? 'otros';
      catAmounts[cat] = (catAmounts[cat] ?? 0) + t.amount;
    }
    final total = catAmounts.values.fold<double>(0, (s, v) => s + v);
    final top = catAmounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    final pct = (top.value / total * 100).round();

    if (pct >= 50) {
      final label = top.key[0].toUpperCase() + top.key.substring(1);
      return _InsightData(
        icon: Icons.bar_chart_rounded,
        text: '$label representa el $pct% de tus gastos recientes',
        color: const Color(0xFFFF9500),
      );
    }
  }

  return null;
}

String? _inferCategory(String note, String? categoryId) {
  if (categoryId != null) return categoryId;
  final t = note.toLowerCase();
  if ([
    'comida',
    'almuerzo',
    'cena',
    'café',
    'cafe',
    'restaurante',
    'super',
    'mercado',
  ].any(t.contains)) {
    return 'comida';
  }
  if ([
    'transporte',
    'taxi',
    'uber',
    'bus',
    'metro',
    'gasolina',
    'coche',
  ].any(t.contains)) {
    return 'transporte';
  }
  if ([
    'servicio',
    'luz',
    'agua',
    'gas',
    'internet',
    'renta',
    'alquiler',
  ].any(t.contains)) {
    return 'servicios';
  }
  if (['compra', 'tienda', 'ropa', 'amazon', 'mall'].any(t.contains)) {
    return 'compras';
  }
  if (['salud', 'medico', 'farmacia', 'gym', 'deporte'].any(t.contains)) {
    return 'salud';
  }
  return null;
}
