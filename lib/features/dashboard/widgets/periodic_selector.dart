import 'package:flutter/material.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_models.dart';
import 'package:provider/provider.dart';

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 4,
        alignment: WrapAlignment.center,
        children: PeriodFilter.values.map((PeriodFilter p) {
          final String label = _getLabel(p);
          final bool isSelected = period == p;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (_) async {
                if (p == PeriodFilter.personalizado) {
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDateRange: logic.customPeriod ??
                        DateTimeRange(
                          start: DateTime.now().subtract(const Duration(days: 7)),
                          end: DateTime.now(),
                        ),
                  );
                  if (picked != null) {
                    logic.changePeriod(p, range: picked);
                  }
                } else {
                  logic.changePeriod(p);
                }
              },
              selectedColor: Colors.blue,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }).toList(),
      ),
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
      case PeriodFilter.personalizado:
        return 'Período';
    }
  }
}
