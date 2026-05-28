import 'package:flutter/material.dart';
import 'package:personal_finance/features/tips/tip_provider.dart';
import 'package:provider/provider.dart';

class TipCard extends StatelessWidget {
  const TipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tipProvider = context.watch<TipProvider>();
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              tipProvider.isLoading ? Icons.hourglass_top : Icons.auto_awesome,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: tipProvider.isLoading
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generando consejo personalizado...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],
                    )
                  : Text(
                      tipProvider.todayTip,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
            if (!tipProvider.isLoading)
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                color: Colors.orange,
                tooltip: 'Nuevo consejo',
                onPressed: () => context.read<TipProvider>().refresh(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
