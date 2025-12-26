import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/budgets/presentation/pages/budgets_crud_page.dart';
import 'package:personal_finance/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:personal_finance/features/home/widgets/custom_bottom_nav_bar.dart';
import 'package:personal_finance/features/profile/presentation/pages/profile_page.dart';
import 'package:personal_finance/features/services/presentation/pages/service_consultation_page.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart'
    as tx_backend;
import 'package:personal_finance/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:personal_finance/features/transactions/presentation/widgets/add_transaction_modal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = <Widget>[
    const DashboardPage(),
    const ServiceConsultationPage(),
    const BudgetsCrudPage(),
    const ProfilePage(),
  ];

  final List<String> _titles = <String>[
    'Finanzas',
    'Servicios',
    'Presupuestos',
    'Perfil',
  ];

  // Mostrar AppBar solo en las pantallas que lo requieren
  final List<bool> _showAppBar = <bool>[true, false, false, true];

  @override
  Widget build(BuildContext context) => BlocProvider<TransactionsBloc>(
    create:
        (BuildContext ctx) => TransactionsBloc(
          ctx.read<tx_backend.TransactionBackendRepository>(),
        )..add(TransactionsLoad()),
    child: Scaffold(
      backgroundColor: Colors.grey[50], // Theme handles this now
      appBar:
          _showAppBar[_currentIndex]
              ? PreferredSize(
                preferredSize: const Size.fromHeight(
                  100,
                ), // Reduced height for cleaner look
                child: Container(
                  // Clean App Bar without heavy gradient, using Theme instead
                  color: Colors.transparent,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getIconForIndex(_currentIndex),
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary, // Use theme color
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _titles[_currentIndex],
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getSubtitleForIndex(_currentIndex),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              : null,
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        onAddPressed: () => _onAddPressed(context),
      ),
      floatingActionButton: Builder(
        builder:
            (BuildContext innerCtx) => FloatingActionButton(
              onPressed: () => _onAddPressed(innerCtx),
              elevation: 4,
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    ),
  );

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard_rounded;
      case 1:
        return Icons.bolt_rounded;
      case 2:
        return Icons.pie_chart_rounded;
      case 3:
        return Icons.person_rounded;
      default:
        return Icons.home;
    }
  }

  String _getSubtitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Resumen de tus finanzas';
      case 1:
        return 'Gestiona tus servicios';
      case 2:
        return 'Planifica tus gastos';
      case 3:
        return 'Configuración y preferencias';
      default:
        return '';
    }
  }

  void _onAddPressed(BuildContext ctx) {
    final TransactionsBloc bloc = ctx.read<TransactionsBloc>();
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (BuildContext _) => BlocProvider.value(
            value: bloc,
            child: const AddTransactionModal(),
          ),
    ).then((_) {
      setState(() {});
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
