import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'tip_provider.dart';

class TipCard extends StatelessWidget {
  const TipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final String tip = context.watch<TipProvider>().todayTip;
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            const Icon(Icons.lightbulb_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tip,
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
