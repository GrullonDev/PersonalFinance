import 'package:flutter/material.dart';
import 'package:personal_finance/features/alerts/pages/alerts_page.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
import 'package:personal_finance/features/dashboard/page/dashboard_layout.dart';
import 'package:personal_finance/features/dashboard/widgets/add_transaction_button.dart';
import 'package:personal_finance/features/profile/pages/profile_page.dart';
import 'package:personal_finance/features/reports/pages/reports_page.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const <Widget>[
    DashboardLayout(),
    ReportsPage(),
    AlertsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Si es el botón de agregar, mostramos el modal
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) => const AddTransactionButton(),
      );
    } else {
      setState(() {
        _selectedIndex = index > 2 ? index - 1 : index;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<DashboardLogic>(
    create: (BuildContext context) => DashboardLogic(),
    child: Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'start-button',
          child: Text(AppLocalizations.of(context)!.appTitle),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex > 2 ? _selectedIndex + 1 : _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    ),
  );
}
