import 'package:flutter/material.dart';

import 'package:personal_finance/features/alerts/pages/alerts_page.dart';
import 'package:personal_finance/features/dashboard/page/dashboard_layout.dart';
import 'package:personal_finance/features/profile/pages/profile_page.dart';
import 'package:personal_finance/features/reports/pages/reports_page.dart';
import 'package:personal_finance/features/transactions/pages/add_transaction_page.dart';
import 'package:personal_finance/utils/app_localization.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = <Widget>[
    const DashboardLayout(),
    const ReportsPage(),
    const AddTransactionPage(),
    const AlertsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Hero(
        tag: 'start-button',
        child: Text(AppLocalizations.of(context)!.appTitle),
      ),
      centerTitle: true,
      elevation: 0,
    ),
    body: IndexedStack(index: _selectedIndex, children: _pages),
    bottomNavigationBar: Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 32),
            label: 'Agregar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    ),
  );
}
