import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';

class PeriodSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const PeriodSelector({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  static const List<String> periods = <String>[
    'Día',
    'Semana',
    'Mes',
    'Año',
    'Período',
  ];

  @override
  Widget build(BuildContext context) {
    final DashboardLogic logic = context.watch<DashboardLogic>();
    final PeriodFilter period = logic.selectedPeriod;

    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children:
          PeriodFilter.values.map((PeriodFilter p) {
            final String label = _getLabel(p);
            final bool isSelected = period == p;

            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => logic.changePeriod(p),
            );
          }).toList(),
    );
  }

  String _getLabel(PeriodFilter filter) {
    switch (filter) {
      case PeriodFilter.dia:
        return 'Día';
      case PeriodFilter.semana:
        return 'Semana';
      case PeriodFilter.mes:
        return 'Mes';
      case PeriodFilter.anio:
        return 'Año';
    }
  }
}
