import 'package:flutter/material.dart';
import 'package:personal_finance/utils/app_localization.dart';

class ShortcutsSetupBottomSheet extends StatelessWidget {
  const ShortcutsSetupBottomSheet({
    required this.onOpenShortcuts,
    required this.onClose,
    super.key,
  });

  final VoidCallback onOpenShortcuts;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    String tr(String key) => AppLocalizations.captureText(context, key);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('captureGuide'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (var i = 1; i <= 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('$i. ${tr('captureStep$i')}'),
              ),
            Text(tr('captureSms')),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed: onClose,
                  child: Text(tr('captureClose')),
                ),
                FilledButton(
                  onPressed: onOpenShortcuts,
                  child: Text(tr('captureOpenShortcuts')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
