import 'package:flutter/material.dart';
import 'package:personal_finance/features/budgets/logic/budgets_logic.dart';
import 'package:personal_finance/features/budgets/widgets/budgets_view.dart';
import 'package:provider/provider.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<BudgetsLogic>(
    create: (_) => BudgetsLogic(),
    child: const BudgetsView(),
  );
}
