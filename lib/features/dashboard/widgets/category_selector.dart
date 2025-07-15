import 'package:flutter/material.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
import 'package:provider/provider.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardLogic logic = context.watch<DashboardLogic>();
    final List<String> categories = logic.availableCategories;
    final String selected = logic.selectedCategory ?? 'Todas';

    return DropdownButton<String>(
      value: selected,
      items: categories
          .map((String cat) => DropdownMenuItem<String>(
                value: cat,
                child: Text(cat),
              ))
          .toList(),
      onChanged: (String? value) {
        if (value != null) {
          logic.changeCategory(value);
        }
      },
    );
  }
}

