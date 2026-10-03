import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShortcutsSetupBottomSheet extends StatelessWidget {
  const ShortcutsSetupBottomSheet({
    required this.onGotIt,
    required this.onRemindLater,
    super.key,
  });

  final VoidCallback onGotIt;
  final VoidCallback onRemindLater;

  static const _urlScheme =
      'personalfinance://pago?monto=[Amount]&comercio=[Merchant Name]&tipo=gasto';

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
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los pagos con Apple Pay se detectan mediante una '
            'automatización gratuita en la app Shortcuts de iOS.',
          ),
          const SizedBox(height: 16),
          const _Step(number: 1, text: 'Abre la app Shortcuts en tu iPhone.'),
          const _Step(number: 2, text: 'Toca "+" → "Nueva automatización".'),
          const _Step(
            number: 3,
            text: 'Selecciona "Apple Pay" como disparador.',
          ),
          const _Step(
            number: 4,
            text: 'Agrega la acción "Abrir URL".',
          ),
          const _Step(number: 5, text: 'Pega la siguiente URL:'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: _urlScheme));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL copiada al portapapeles'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _urlScheme,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const Icon(Icons.copy, size: 16),
                ],
              ),
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
