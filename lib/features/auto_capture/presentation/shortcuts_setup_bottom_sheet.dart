import 'package:flutter/material.dart';

class ShortcutsSetupBottomSheet extends StatelessWidget {
  const ShortcutsSetupBottomSheet({
    required this.onGotIt,
    required this.onRemindLater,
    super.key,
  });

  final VoidCallback onGotIt;
  final VoidCallback onRemindLater;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shortcut_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            'Configurar Apple Pay con Shortcuts',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los pagos con Apple Pay se detectan con una automatización '
            'gratuita en la app Atajos (Shortcuts) de iOS.',
          ),
          const SizedBox(height: 16),
          const _Step(
            number: 1,
            text:
                'Abre Atajos → pestaña "Automatización" → "+" → '
                '"Transacción".',
          ),
          const _Step(
            number: 2,
            text:
                'Elige "Cualquier tarjeta", marca "Ejecutar inmediatamente" '
                'y toca "Siguiente".',
          ),
          const _Step(
            number: 3,
            text:
                'Toca "Nuevo atajo en blanco" y busca la acción '
                '"Registrar pago" de esta app.',
          ),
          const _Step(
            number: 4,
            text:
                'En "Monto" toca y elige la variable "Importe"; en "Comercio" '
                'elige "Comerciante". No escribas el texto a mano.',
          ),
          const _Step(
            number: 5,
            text:
                'Listo: al pagar con Apple Pay el gasto se registra y se '
                'categoriza solo, aunque la app esté cerrada.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No uses "Abrir URL" ni "Abrir en Chrome": la acción '
              '"Registrar pago" no necesita abrir ningún enlace.',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRemindLater,
                  child: const Text('Recordarme después'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onGotIt,
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text('$number', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
