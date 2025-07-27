import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/features/alerts/alert_item.dart';
import 'package:personal_finance/features/alerts/alerts_provider.dart';
import 'package:provider/provider.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AlertsProvider>(
    builder: (BuildContext context, AlertsProvider provider, _) {
      if (provider.alerts.isEmpty) {
        return const Center(child: Text('Sin alertas por el momento'));
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.alerts.length,
        itemBuilder: (BuildContext context, int index) {
          final AlertItem alert = provider.alerts[index];
          return ListTile(
            leading: const Icon(Icons.notifications_active),
            title: Text(alert.title),
            subtitle: Text(alert.description),
            trailing: Text(DateFormat('dd/MM').format(alert.date)),
          );
        },
        separatorBuilder: (_, _) => const Divider(),
      );
    },
  );
}
