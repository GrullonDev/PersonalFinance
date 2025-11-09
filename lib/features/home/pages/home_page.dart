import 'package:flutter/material.dart';

import 'package:personal_finance/features/budgets/presentation/pages/budgets_crud_page.dart';
import 'package:personal_finance/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:personal_finance/features/goals/presentation/pages/goals_crud_page.dart';
import 'package:personal_finance/features/home/widgets/custom_bottom_nav_bar.dart';
import 'package:personal_finance/features/profile/presentation/pages/profile_page.dart';
import 'package:personal_finance/features/transactions/presentation/widgets/add_transaction_modal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart'
    as tx_backend;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = <Widget>[
    const DashboardPage(),
    const BudgetsCrudPage(),
    const GoalsCrudPage(),
    const ProfilePage(),
  ];

  final List<String> _titles = <String>[
    'Finanzas',
    'Presupuestos',
    'Metas',
    'Perfil',
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
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

  @override
  Widget build(BuildContext context) => BlocProvider<TransactionsBloc>(
    create:
        (BuildContext ctx) => TransactionsBloc(
          ctx.read<tx_backend.TransactionBackendRepository>(),
        )..add(TransactionsLoad()),
    child: Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
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
              backgroundColor: Colors.blue,
              elevation: 4,
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    ),
  );
}
