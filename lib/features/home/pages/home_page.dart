import 'package:flutter/material.dart';

import 'package:personal_finance/features/alerts/pages/alerts_page.dart';
import 'package:personal_finance/features/dashboard/page/dashboard_page.dart';
import 'package:personal_finance/features/profile/pages/profile_page.dart';
import 'package:personal_finance/features/reports/pages/reports_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const <Widget>[
    DashboardPage(),
    ReportsPage(),
    AlertsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _pages[_selectedIndex],
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
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
