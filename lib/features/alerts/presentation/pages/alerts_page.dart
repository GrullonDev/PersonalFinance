import 'package:flutter/material.dart';
import 'package:personal_finance/features/alerts/presentation/providers/alerts_logic.dart';
import 'package:personal_finance/features/alerts/presentation/widgets/alerts_view.dart';
import 'package:provider/provider.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<AlertsLogic>(
    create: (_) => AlertsLogic()..loadAlerts(),
    child: const AlertsView(),
  );
}
