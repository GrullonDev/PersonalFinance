import 'package:flutter/material.dart';

import 'package:personal_finance/features/budgets/presentation/pages/budgets_crud_page.dart';
import 'package:personal_finance/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:personal_finance/features/goals/presentation/pages/goals_crud_page.dart';
import 'package:personal_finance/features/home/widgets/custom_bottom_nav_bar.dart';
import 'package:personal_finance/features/profile/presentation/pages/profile_page.dart';
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

  void _onAddPressed() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => const AddTransactionModal(),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
      onAddPressed: _onAddPressed,
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _onAddPressed,
      backgroundColor: Colors.blue,
      elevation: 4,
      child: const Icon(Icons.add, size: 32, color: Colors.white),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
  );
}
