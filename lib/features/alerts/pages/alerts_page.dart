import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/features/alerts/alert_item.dart';
import 'package:personal_finance/features/alerts/alerts_provider.dart';
import 'package:personal_finance/features/alerts/widgets/add_alert_modal.dart';
import 'package:provider/provider.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  void _showAddAlertModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const AddAlertModal(),
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<AlertsProvider>(
        builder: (BuildContext context, AlertsProvider provider, _) => Stack(
          children: <Widget>[
            if (provider.alerts.isEmpty)
              const Center(child: Text('Sin alertas por el momento'))
            else
              ListView.separated(
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
                separatorBuilder: (_, __) => const Divider(),
              ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _showAddAlertModal(context),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      );
}
