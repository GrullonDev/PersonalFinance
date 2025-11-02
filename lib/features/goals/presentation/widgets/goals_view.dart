import 'package:flutter/material.dart';
import 'package:personal_finance/features/goals/presentation/providers/goals_logic.dart';
import 'package:personal_finance/features/goals/domain/entities/goal_models.dart';
import 'package:provider/provider.dart';

class GoalsView extends StatelessWidget {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    final GoalsLogic logic = context.watch<GoalsLogic>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Icon(
                  logic.notificationsEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: logic.notificationsEnabled ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notificaciones de progreso',
                  style: TextStyle(fontSize: 14),
                ),
                const Spacer(),
                Switch(
                  value: logic.notificationsEnabled,
                  onChanged: (bool value) => logic.toggleNotifications(),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                logic.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : logic.error != null
                    ? Center(child: Text(logic.error!))
                    : _buildContent(context, logic),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, GoalsLogic logic) {
    if (!logic.hasGoals) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.flag_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tienes metas de ahorro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade tu primera meta tocando el botón +',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logic.goals.length,
      itemBuilder:
          (BuildContext context, int index) =>
              _GoalCard(goal: logic.goals[index]),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: goal.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(goal.icon, color: goal.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${goal.currentAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${(goal.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: goal.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    goal.formattedTimeLeft,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              if (goal.isLinkedToBudget)
                _buildLink('Vinculado a Presupuesto', Icons.pie_chart),
              if (goal.isLinkedToDco)
                _buildLink('Vinculado a DCO', Icons.account_balance),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // TODO: Implementar menú de opciones
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildLink(String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(right: 16),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    ),
  );
}
