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
  late final AnimationController _syncIconController;

  @override
  void initState() {
    super.initState();
    _syncIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    context.read<QuickFinanceBloc>().add(const WatchDataRequested());
  }

  @override
  void dispose() {
    _syncIconController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<QuickFinanceBloc>();
    bloc.add(const SyncTransactionsRequested());
    // Esperar un breve momento para que el pull-to-refresh se sienta natural
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocConsumer<QuickFinanceBloc, QuickFinanceState>(
        listenWhen: (prev, curr) =>
            // Errores
            (curr.status == QuickFinanceStatus.failure &&
                curr.errorMessage != null &&
                prev.errorMessage != curr.errorMessage) ||
            // Sync terminó (pasó de syncing a no syncing)
            (prev.isSyncing && !curr.isSyncing),
        listener: (context, state) {
          // Error snackbar
          if (state.status == QuickFinanceStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // Controlar animación del icono de sync
          if (state.isSyncing) {
            _syncIconController.repeat();
          } else {
            _syncIconController.stop();
            _syncIconController.reset();
          }
        },
        builder: (context, state) {
          if (state.status == QuickFinanceStatus.loading &&
              state.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildBody(context, state);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Quick Finance',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      actions: [
        BlocBuilder<QuickFinanceBloc, QuickFinanceState>(
          buildWhen: (prev, curr) => prev.isSyncing != curr.isSyncing,
          builder: (context, state) {
            return IconButton(
              icon: RotationTransition(
                turns: _syncIconController,
                child: Icon(
                  Icons.sync_rounded,
                  color: state.isSyncing
                      ? Theme.of(context).primaryColor
                      : null,
                ),
              ),
              tooltip: state.isSyncing ? 'Sincronizando...' : 'Sincronizar',
              onPressed: state.isSyncing
                  ? null
                  : () => context
                      .read<QuickFinanceBloc>()
                      .add(const SyncTransactionsRequested()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, QuickFinanceState state) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Theme.of(context).primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: BalanceCard(balance: state.balance),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Entrada Rápida',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  QuickEntryInput(
                    onAdd: (amount, type, note) => context
                        .read<QuickFinanceBloc>()
                        .add(AddTransactionRequested(
                          amount: amount,
                          type: type,
                          note: note,
                        )),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Transacciones Recientes',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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
