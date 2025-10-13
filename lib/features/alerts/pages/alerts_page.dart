import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:personal_finance/features/alerts/logic/alerts_logic.dart';
import 'package:personal_finance/features/alerts/widgets/alerts_view.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<AlertsLogic>(
    create: (_) => AlertsLogic()..loadAlerts(),
    child: const AlertsView(),
  );
}
