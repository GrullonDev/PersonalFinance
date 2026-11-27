import 'package:flutter/material.dart';

import 'package:personal_finance/utils/app_localization.dart';

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
    String tr(String key) => AppLocalizations.captureText(context, key);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_active_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            tr('captureAndroidTitle'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(tr('captureAndroidIntro')),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onNotNow,
                  child: Text(tr('captureNotNow')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onEnable,
                  child: Text(tr('captureEnable')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
