import 'package:flutter/material.dart';

class NotificationAccessBottomSheet extends StatelessWidget {
  const NotificationAccessBottomSheet({
    required this.onEnable,
    required this.onNotNow,
    super.key,
  });

  final VoidCallback onEnable;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_active_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            'Acceso a notificaciones',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para detectar pagos automáticamente, la app necesita '
            'permiso para leer notificaciones de apps de pago y banco. '
            'Solo se procesan notificaciones que contienen montos y comercios.',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onNotNow,
                  child: const Text('Ahora no'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onEnable,
                  child: const Text('Activar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
