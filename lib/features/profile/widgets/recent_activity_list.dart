import 'package:flutter/material.dart';

import 'package:personal_finance/features/profile/logic/profile_logic.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({required this.activities, super.key});

  final List<ActivityItem> activities;

  @override
  Widget build(BuildContext context) => SliverList(
    delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
      final ActivityItem activity = activities[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _ActivityCard(activity: activity),
      );
    }, childCount: activities.length),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final ActivityItem activity;

  IconData _getActivityIcon() {
    switch (activity.type) {
      case ActivityType.expense:
        return Icons.arrow_downward;
      case ActivityType.income:
        return Icons.arrow_upward;
      case ActivityType.goal:
        return Icons.flag;
      case ActivityType.budget:
        return Icons.account_balance_wallet;
    }
  }

  Color _getActivityColor(BuildContext context) {
    switch (activity.type) {
      case ActivityType.expense:
        return Colors.red;
      case ActivityType.income:
        return Colors.green;
      case ActivityType.goal:
        return Theme.of(context).primaryColor;
      case ActivityType.budget:
        return Colors.orange;
    }
  }

  String _formatTimestamp() {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(activity.timestamp);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} días';
    }
    if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} horas';
    }
    if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minutos';
    }
    return 'Ahora';
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getActivityColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getActivityIcon(), color: _getActivityColor(context)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (activity.description != null)
                  Text(
                    activity.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  _formatTimestamp(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '\$${activity.amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: _getActivityColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
