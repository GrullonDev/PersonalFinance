import 'package:flutter/material.dart';
import 'package:personal_finance/features/dashboard/page/dashboard_page.dart';
import 'package:personal_finance/features/budgets/pages/budgets_page.dart';
import 'package:personal_finance/features/goals/pages/goals_page.dart';
import 'package:personal_finance/features/home/widgets/custom_bottom_nav_bar.dart';
import 'package:personal_finance/features/profile/pages/profile_page.dart';
import 'package:personal_finance/features/transactions/pages/add_transaction_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = <Widget>[
    const DashboardPage(),
    const BudgetsPage(),
    const GoalsPage(),
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
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const AddTransactionPage(),
      ),
    ).then((_) {
      // Actualizar después de agregar transacción
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[50],
    appBar:
        _currentIndex == 0
            ? null
            : AppBar(
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
