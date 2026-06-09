import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/utils/currency_helper.dart';

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
    final user = context.watch<AuthProvider>().currentUser;
    final shortName = _buildShortName(user?.fullName);
    final greeting = _buildGreeting();

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          Text(
            shortName ?? 'Mis finanzas',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      elevation: 0,
      scrolledUnderElevation: 1,
      actions: [
        BlocBuilder<QuickFinanceBloc, QuickFinanceState>(
          buildWhen: (prev, curr) => prev.isSyncing != curr.isSyncing,
          builder: (context, state) => IconButton(
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
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Configuración',
          onPressed: () => Navigator.of(context).pushNamed(RoutePath.settings),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  String _buildGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días,';
    if (hour < 18) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  String? _buildShortName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return null;
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final first = parts.first;
    if (parts.length == 1) return first;
    return '$first ${parts.last[0].toUpperCase()}.';
  }
}


// ── AI chat banner ────────────────────────────────────────────────────────────

class _AIChatCard extends StatelessWidget {
  const _AIChatCard();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SubscriptionBloc, SubscriptionState>(
        bloc: getIt<SubscriptionBloc>(),
        builder: (context, state) {
          final isPremium = state.isPremium;
          final primary = Theme.of(context).primaryColor;

          return GestureDetector(
            onTap: () {
              if (isPremium) {
                Navigator.of(context).pushNamed(RoutePath.aiChat);
              } else {
                PaywallPage.show(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(primary, Colors.black, 0.04)!,
                    Color.lerp(primary, const Color(0xFF1A237E), 0.30)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Asistente Financiero IA',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (!isPremium) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPremium
                              ? 'Consulta tu situación financiera ahora'
                              : 'Análisis y consejos personalizados con IA',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Text(
                      isPremium ? 'Chatear' : 'Ver Plan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
  String _txFilter = 'semana';
  bool _insightDismissed = false;

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
    final insight =
        _insightDismissed ? null : _computeInsight(widget.state.transactions);
    final pendingCount =
        widget.state.transactions
            .where(
              (t) => t.syncStatus == SyncStatus.pending && t.deletedAt == null,
            )
            .length;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));

    final filteredTx = switch (_txFilter) {
      'hoy' => widget.state.transactions
          .where(
            (t) =>
                t.deletedAt == null &&
                DateTime(
                      t.createdAt.year,
                      t.createdAt.month,
                      t.createdAt.day,
                    ) ==
                    today,
          )
          .toList(),
      'mes' => widget.state.transactions
          .where(
            (t) =>
                t.deletedAt == null &&
                t.createdAt.year == now.year &&
                t.createdAt.month == now.month,
          )
          .toList(),
      _ => widget.state.transactions
          .where(
            (t) => t.deletedAt == null && !t.createdAt.isBefore(monday),
          )
          .toList(),
    };

    final primary = Theme.of(context).primaryColor;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Balance card
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: BalanceCard(
                transactions: widget.state.transactions,
                forceHidden: widget.hideAmounts,
              ),
            ),
          ),
          // 2. Quick entry — right below balance for instant capture
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operativa',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gestión inmediata',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
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
          // 3. AI chat banner
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(child: _AIChatCard()),
          ),
          // 4. Sync status
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _SyncStatusRow(
                isSyncing: widget.state.isSyncing,
                pendingCount: pendingCount,
                isOffline: widget.state.isOffline,
                hasSyncError: widget.state.syncError != null,
              ),
            ),
          ),
          if (widget.state.transactions.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _WeeklyBudgetCard(
                  transactions: widget.state.transactions,
                  hideAmounts: widget.hideAmounts,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _FinancialHealthCard(
                  transactions: widget.state.transactions,
                ),
              ),
            ),
          ],
          if (insight != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _InsightsSection(
                  insight: insight,
                  onDismiss: () => setState(() => _insightDismissed = true),
                ),
              ),
            ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
            sliver: SliverToBoxAdapter(child: _QuickActionsRow()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transacciones',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (widget.state.transactions.isNotEmpty)
                        Text(
                          '${filteredTx.length} registros',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final (label, val) in [
                        ('Hoy', 'hoy'),
                        ('Semana', 'semana'),
                        ('Mes', 'mes'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _txFilter = val),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _txFilter == val
                                        ? primary
                                        : primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _txFilter == val
                                          ? Colors.white
                                          : primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            sliver: SliverToBoxAdapter(
              child: TransactionsList(
                hideAmounts: widget.hideAmounts,
                transactions: filteredTx,
                onDelete: (id) => context.read<QuickFinanceBloc>().add(
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

  // ── Datos del mes actual ──────────────────────────────────────────────────
  final thisMonthExp = transactions.where(
    (t) =>
        t.deletedAt == null &&
        t.type == TransactionType.expense &&
        t.createdAt.year == now.year &&
        t.createdAt.month == now.month,
  );
  final thisMonthInc = transactions.where(
    (t) =>
        t.deletedAt == null &&
        t.type == TransactionType.income &&
        t.createdAt.year == now.year &&
        t.createdAt.month == now.month,
  );

  final totalExp = thisMonthExp.fold<double>(0, (s, t) => s + t.amount);
  final totalInc = thisMonthInc.fold<double>(0, (s, t) => s + t.amount);

  final lastMonthDate =
      now.month == 1
          ? DateTime(now.year - 1, 12)
          : DateTime(now.year, now.month - 1);

  final lastMonthExpList = transactions
      .where(
        (t) =>
            t.deletedAt == null &&
            t.type == TransactionType.expense &&
            t.createdAt.year == lastMonthDate.year &&
            t.createdAt.month == lastMonthDate.month,
      )
      .toList();

  // ── PRIORIDAD 1: Gastos superan ingresos este mes ─────────────────────────
  if (totalInc > 0 && totalExp > totalInc) {
    final diff = CurrencyHelper.format(totalExp - totalInc);
    return _InsightData(
      icon: Icons.warning_amber_rounded,
      text:
          'Tus gastos superan tus ingresos este mes por $diff. '
          'Considera reducir gastos no esenciales.',
      color: const Color(0xFFFF3B30),
    );
  }

  // ── PRIORIDAD 2: Buena tasa de ahorro → sugerir meta ─────────────────────
  if (totalInc > 0) {
    final savingsRate = (totalInc - totalExp) / totalInc;
    if (savingsRate >= 0.2) {
      final saved = CurrencyHelper.format(totalInc - totalExp);
      final pct = (savingsRate * 100).round();
      return _InsightData(
        icon: Icons.savings_outlined,
        text:
            '¡Excelente! Estás ahorrando el $pct% de tus ingresos este mes ($saved). '
            '¿Quieres programar una transferencia a tu meta de ahorro?',
        color: const Color(0xFF34C759),
      );
    }
  }

  // ── PRIORIDAD 3: Reducción de categoría vs mes anterior ──────────────────
  final thisMonthExpList = thisMonthExp.toList();
  if (thisMonthExpList.isNotEmpty && lastMonthExpList.isNotEmpty) {
    final thisByCat = <String, double>{};
    for (final t in thisMonthExpList) {
      final cat = _inferCategory(t.note, t.categoryId) ?? 'otros';
      thisByCat[cat] = (thisByCat[cat] ?? 0) + t.amount;
    }
    final lastByCat = <String, double>{};
    for (final t in lastMonthExpList) {
      final cat = _inferCategory(t.note, t.categoryId) ?? 'otros';
      lastByCat[cat] = (lastByCat[cat] ?? 0) + t.amount;
    }
    for (final entry in lastByCat.entries) {
      final thisAmt = thisByCat[entry.key] ?? 0;
      if (entry.value > 0 && thisAmt < entry.value) {
        final redPct = ((entry.value - thisAmt) / entry.value * 100).round();
        if (redPct >= 10) {
          final label = entry.key[0].toUpperCase() + entry.key.substring(1);
          final saved = CurrencyHelper.format(entry.value - thisAmt);
          return _InsightData(
            icon: Icons.trending_down_rounded,
            text:
                '¡Buen trabajo! Has reducido tus gastos en $label un $redPct% '
                '($saved menos). ¿Quieres programar esa diferencia a tu meta de ahorro?',
            color: const Color(0xFF34C759),
          );
        }
      }
    }
  }

  // ── PRIORIDAD 4: Categoría dominante esta semana ──────────────────────────
  final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final weekExp = transactions
      .where(
        (t) =>
            t.deletedAt == null &&
            t.type == TransactionType.expense &&
            !t.createdAt.isBefore(weekStart),
      )
      .toList();

  if (weekExp.length >= 3) {
    final catAmounts = <String, double>{};
    for (final t in weekExp) {
      final cat = _inferCategory(t.note, t.categoryId) ?? 'otros';
      catAmounts[cat] = (catAmounts[cat] ?? 0) + t.amount;
    }
    final total = catAmounts.values.fold<double>(0, (s, v) => s + v);
    final top = catAmounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    final pct = (top.value / total * 100).round();
    if (pct >= 50) {
      final label = top.key[0].toUpperCase() + top.key.substring(1);
      final topAmt = CurrencyHelper.format(top.value);
      return _InsightData(
        icon: Icons.bar_chart_rounded,
        text:
            '$label representa el $pct% de tus gastos esta semana ($topAmt). '
            '¿Quieres establecer un límite de presupuesto?',
        color: const Color(0xFFFF9500),
      );
    }
  }

  // ── RECORDATORIO: Sin movimientos hoy ────────────────────────────────────
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
      text:
          'No has registrado movimientos hoy. ¿Deseas agregar tus gastos del día?',
      color: Color(0xFF007AFF),
    );
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

// ── Weekly budget card ────────────────────────────────────────────────────────

class _WeeklyBudgetCard extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final bool hideAmounts;

  const _WeeklyBudgetCard({
    required this.transactions,
    required this.hideAmounts,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final now = DateTime.now();

    final monthlyExpenses = transactions
        .where(
          (t) =>
              t.deletedAt == null &&
              t.type == TransactionType.expense &&
              t.createdAt.year == now.year &&
              t.createdAt.month == now.month,
        )
        .fold<double>(0, (s, t) => s + t.amount);

    final monthlyIncome = transactions
        .where(
          (t) =>
              t.deletedAt == null &&
              t.type == TransactionType.income &&
              t.createdAt.year == now.year &&
              t.createdAt.month == now.month,
        )
        .fold<double>(0, (s, t) => s + t.amount);

    final budget =
        monthlyIncome > 0 ? monthlyIncome : monthlyExpenses * 1.4;
    final ratio =
        budget > 0 ? (monthlyExpenses / budget).clamp(0.0, 1.0) : 0.0;
    final pctInt = (ratio * 100).round();
    final indicatorColor = ratio > 0.9 ? Colors.red : primary;

    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final dailyExp = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return transactions
          .where(
            (t) =>
                t.deletedAt == null &&
                t.type == TransactionType.expense &&
                t.createdAt.year == day.year &&
                t.createdAt.month == day.month &&
                t.createdAt.day == day.day,
          )
          .fold<double>(0, (s, t) => s + t.amount);
    });

    final maxExp =
        dailyExp.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    const labels = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final todayIdx = now.weekday - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gasto vs Presupuesto',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hideAmounts
                        ? '•••• / ••••'
                        : '${CurrencyHelper.format(monthlyExpenses)} / ${CurrencyHelper.format(budget)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: ratio,
                      strokeWidth: 5,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                    ),
                    Text(
                      hideAmounts ? '—' : '$pctInt%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: indicatorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday = i == todayIdx;
              final barH =
                  ((dailyExp[i] / maxExp) * 60).clamp(4.0, 60.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 32,
                    height: barH,
                    decoration: BoxDecoration(
                      color: isToday
                          ? primary
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isToday ? 'Hoy' : labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? primary : Colors.grey.shade500,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Financial health card ─────────────────────────────────────────────────────

class _FinancialHealthCard extends StatelessWidget {
  final List<TransactionEntity> transactions;

  const _FinancialHealthCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final monthIncome = transactions
        .where(
          (t) =>
              t.deletedAt == null &&
              t.type == TransactionType.income &&
              t.createdAt.year == now.year &&
              t.createdAt.month == now.month,
        )
        .fold<double>(0, (s, t) => s + t.amount);

    final monthExp = transactions
        .where(
          (t) =>
              t.deletedAt == null &&
              t.type == TransactionType.expense &&
              t.createdAt.year == now.year &&
              t.createdAt.month == now.month,
        )
        .fold<double>(0, (s, t) => s + t.amount);

    final lastMonthDate =
        now.month == 1
            ? DateTime(now.year - 1, 12)
            : DateTime(now.year, now.month - 1);

    final lastMonthExp = transactions
        .where(
          (t) =>
              t.deletedAt == null &&
              t.type == TransactionType.expense &&
              t.createdAt.year == lastMonthDate.year &&
              t.createdAt.month == lastMonthDate.month,
        )
        .fold<double>(0, (s, t) => s + t.amount);

    String title;
    String description;
    double score;

    if (monthIncome == 0 && monthExp == 0) {
      title = 'Sin datos';
      description =
          'Registra ingresos y gastos para ver tu salud financiera.';
      score = 0.0;
    } else if (monthIncome == 0) {
      title = 'Regular';
      description = 'No se han registrado ingresos este mes.';
      score = 0.35;
    } else {
      final savingsRate = (monthIncome - monthExp) / monthIncome;
      if (savingsRate >= 0.3) {
        title = 'Excelente';
        score = 0.92;
        if (lastMonthExp > 0 && monthExp < lastMonthExp) {
          final redPct =
              ((lastMonthExp - monthExp) / lastMonthExp * 100).round();
          description =
              'Has ahorrado un $redPct% más que el mes pasado. ¡Sigue así!';
        } else {
          description =
              'Tu tasa de ahorro es del ${(savingsRate * 100).round()}%. ¡Excelente manejo!';
        }
      } else if (savingsRate >= 0.15) {
        title = 'Buena';
        score = 0.68;
        description =
            'Estás ahorrando el ${(savingsRate * 100).round()}% de tus ingresos.';
      } else if (savingsRate >= 0) {
        title = 'Regular';
        score = 0.45;
        description =
            'Tus gastos son casi iguales a tus ingresos. Reduce gastos no esenciales.';
      } else {
        title = 'Crítica';
        score = 0.2;
        description =
            'Tus gastos superan tus ingresos. Revisa tu presupuesto urgente.';
      }
    }

    const green = Color(0xFF34C759);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Salud Financiera',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: green,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(green),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Insights section ──────────────────────────────────────────────────────────

class _InsightsSection extends StatelessWidget {
  final _InsightData insight;
  final VoidCallback onDismiss;

  const _InsightsSection({required this.insight, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: primary),
            const SizedBox(width: 8),
            Text(
              'Insights de IA',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight.text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(RoutePath.goals),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.onSurface,
                        foregroundColor:
                            Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Programar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Ahora no',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
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
}
