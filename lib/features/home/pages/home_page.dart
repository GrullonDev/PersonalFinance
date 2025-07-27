import 'package:flutter/material.dart';
import 'package:personal_finance/features/alerts/pages/alerts_page.dart';
import 'package:personal_finance/features/dashboard/page/dashboard_page.dart';
import 'package:personal_finance/features/navigation/navigation_provider.dart';
import 'package:personal_finance/features/profile/pages/profile_page.dart';
import 'package:personal_finance/features/reports/pages/reports_page.dart';
import 'package:personal_finance/features/transactions/pages/add_transaction_page.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Widget> _pages = const <Widget>[
    DashboardPage(),
    ReportsPage(),
    AddTransactionPage(),
    AlertsPage(),
    ProfilePage(),
  ];

  Widget _getTitle(int index) {
    switch (index) {
      case 0:
        return Hero(
          tag: 'start-button',
          child: const Text('Personal Finance'),
        );
      case 1:
        return const Text('Reportes');
      case 2:
        return const Text('Agregar');
      case 3:
        return const Text('Alertas');
      case 4:
        return const Text('Perfil');
      default:
        return const Text('Personal Finance');
    }
  }

  @override
  void initState() {
    super.initState();
    print('HomePage initialized');
  }

  @override
  Widget build(BuildContext context) {
    // Usar watch para reconstruir cuando cambie el estado
    final NavigationProvider provider = context.watch<NavigationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: _getTitle(provider.currentIndex),
        centerTitle: true,
        elevation: 0,
      ),
      body: _pages[provider.currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: provider.currentIndex,
        onTap: provider.setIndex,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Agregar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
