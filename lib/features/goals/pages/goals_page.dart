import 'package:flutter/material.dart';
import 'package:personal_finance/features/goals/logic/goals_logic.dart';
import 'package:personal_finance/features/goals/widgets/goals_view.dart';
import 'package:provider/provider.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<GoalsLogic>(
    create: (_) => GoalsLogic()..loadGoals(),
    child: const GoalsView(),
  );
}
