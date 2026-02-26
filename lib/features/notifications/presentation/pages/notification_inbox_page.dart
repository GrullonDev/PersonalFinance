import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_item.dart';
import 'package:personal_finance/features/notifications/presentation/providers/notification_inbox_provider.dart';

class NotificationInboxPage extends StatefulWidget {
  const NotificationInboxPage({super.key});

  @override
  State<NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends State<NotificationInboxPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationInboxProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Centro de Notificaciones'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              _showClearConfirmation(context);
            },
            tooltip: 'Limpiar todo',
          ),
        ],
      ),
      body: Consumer<NotificationInboxProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: provider.fetchNotifications,
            child: ListView.separated(
              itemCount: provider.notifications.length,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _buildNotificationCard(context, notification, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Aquí aparecerán tus avisos de pagos, presupuestos y más.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItem notification,
    NotificationInboxProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isRead = notification.isRead;

    return InkWell(
      onTap: () {
        if (!isRead) {
          provider.markAsRead(notification.id);
        }
        // Handle deep linking or detail view if needed
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isRead
                  ? colorScheme.surface
                  : colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isRead
                    ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                    : colorScheme.primary.withValues(alpha: 0.3),
          ),
          boxShadow:
              isRead
                  ? null
                  : [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeIcon(context, notification.type, isRead),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 15,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat(
                      'dd MMM, hh:mm a',
                    ).format(notification.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(BuildContext context, String? type, bool isRead) {
    final colorScheme = Theme.of(context).colorScheme;
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'payment':
        iconData = Icons.receipt_long_outlined;
        iconColor = Colors.orange;
        break;
      case 'budget':
        iconData = Icons.account_balance_wallet_outlined;
        iconColor = Colors.red;
        break;
      case 'goal':
        iconData = Icons.savings_outlined;
        iconColor = Colors.green;
        break;
      case 'security':
        iconData = Icons.security_outlined;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications_outlined;
        iconColor = colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('¿Vaciar notificaciones?'),
            content: const Text(
              'Esta acción eliminará todo el historial de notificaciones permanentemente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  context.read<NotificationInboxProvider>().clearAll();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar todo'),
              ),
            ],
          ),
    );
  }
}
