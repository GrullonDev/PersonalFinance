import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/quick_finance_bloc.dart';
import '../bloc/quick_finance_event.dart';
import '../bloc/quick_finance_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_entry_input.dart';
import '../widgets/transactions_list.dart';

class QuickFinanceHomePage extends StatefulWidget {
  const QuickFinanceHomePage({super.key});

  @override
  State<QuickFinanceHomePage> createState() => _QuickFinanceHomePageState();
}

class _QuickFinanceHomePageState extends State<QuickFinanceHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _syncAnim;

  @override
  void initState() {
    super.initState();

    _syncAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Iniciar streams y triggers de sync
    context.read<QuickFinanceBloc>().add(const WatchDataRequested());

    // Si el BLoC ya está sincronizando al montar el widget (race condition),
    // iniciar la animación en el siguiente frame
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

  // Espera a que el sync finalice antes de liberar el indicador de refresh
  Future<void> _onRefresh() async {
    final bloc = context.read<QuickFinanceBloc>();
    bloc.add(const SyncTransactionsRequested());

    // Escucha el stream del BLoC hasta que isSyncing vuelva a false
    // o se alcance el timeout de 15 s
    await bloc.stream
        .firstWhere((s) => !s.isSyncing)
        .timeout(const Duration(seconds: 15), onTimeout: () => bloc.state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: BlocListener<QuickFinanceBloc, QuickFinanceState>(
        // Escucha cambios de error Y cualquier cambio de estado de sync
        listenWhen: (prev, curr) =>
            (curr.status == QuickFinanceStatus.failure &&
                curr.errorMessage != null &&
                prev.errorMessage != curr.errorMessage) ||
            (prev.isSyncing != curr.isSyncing),
        listener: (context, state) {
          // Error snackbar
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

          // Animación del icono de sync
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
            // Pantalla de carga inicial (primera vez, sin datos aún)
            if (state.status == QuickFinanceStatus.loading &&
                state.transactions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return _Body(onRefresh: _onRefresh, state: state);
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Quick Finance',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      actions: [
        // Rebuild mínimo: solo cuando cambia isSyncing
        BlocBuilder<QuickFinanceBloc, QuickFinanceState>(
          buildWhen: (prev, curr) => prev.isSyncing != curr.isSyncing,
          builder: (context, state) => IconButton(
            icon: RotationTransition(
              turns: _syncAnim,
              child: Icon(
                Icons.sync_rounded,
                color: state.isSyncing
                    ? Theme.of(context).primaryColor
                    : null,
              ),
            ),
            tooltip: state.isSyncing ? 'Sincronizando…' : 'Sincronizar',
            onPressed: state.isSyncing
                ? null
                : () => context
                    .read<QuickFinanceBloc>()
                    .add(const SyncTransactionsRequested()),
          ),
        ),
      ],
    );
  }
}

// ── Cuerpo principal ─────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final QuickFinanceState state;

  const _Body({required this.onRefresh, required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Balance card ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: BalanceCard(balance: state.balance),
            ),
          ),

          // ── Entrada rápida ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entrada rápida',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  QuickEntryInput(
                    onSubmit: (raw) => context
                        .read<QuickFinanceBloc>()
                        .add(RawEntrySubmitted(raw)),
                  ),
                ],
              ),
            ),
          ),

          // ── Encabezado de lista ───────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Movimientos recientes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (state.transactions.isNotEmpty)
                    Text(
                      '${state.transactions.length} registros',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Lista de transacciones ────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverToBoxAdapter(
              child: TransactionsList(
                transactions: state.transactions,
                onDelete: (id) => context
                    .read<QuickFinanceBloc>()
                    .add(DeleteTransactionRequested(id)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
