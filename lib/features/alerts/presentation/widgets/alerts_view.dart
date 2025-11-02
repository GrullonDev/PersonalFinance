import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/features/alerts/domain/entities/alert_item.dart';
import 'package:personal_finance/features/alerts/presentation/providers/alerts_logic.dart';
import 'package:personal_finance/features/alerts/presentation/widgets/add_alert_modal.dart';
import 'package:provider/provider.dart';

class AlertsView extends StatelessWidget {
  const AlertsView({super.key});

  void _showAddAlertModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const AddAlertModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AlertsLogic logic = context.watch<AlertsLogic>();

    return Stack(
      children: <Widget>[
        if (logic.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (logic.error != null)
          Center(child: Text(logic.error!))
        else if (!logic.hasAlerts)
          const Center(child: Text('Sin alertas por el momento'))
        else
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logic.alerts.length,
            itemBuilder: (BuildContext context, int index) {
              final AlertItem alert = logic.alerts[index];
              return Dismissible(
                key: Key(alert.title + alert.date.toString()),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => logic.removeAlert(alert),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: Text(alert.title),
                  subtitle: Text(alert.description),
                  trailing: Text(DateFormat('dd/MM').format(alert.date)),
                ),
              );
            },
            separatorBuilder: (BuildContext context, int _) => const Divider(),
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showAddAlertModal(context),
            heroTag: 'add_alert_fab',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
