import 'package:flutter/material.dart';
import 'package:personal_finance/features/transactions/presentation/providers/transaction_filters_logic.dart';
import 'package:provider/provider.dart';

class TransactionFiltersModal extends StatelessWidget {
  const TransactionFiltersModal({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<TransactionFiltersLogic>(
        create: (_) => TransactionFiltersLogic(),
        child: const _TransactionFiltersView(),
      );
}

class _TransactionFiltersView extends StatelessWidget {
  const _TransactionFiltersView();

  @override
  Widget build(BuildContext context) {
    final TransactionFiltersLogic logic = Provider.of<TransactionFiltersLogic>(
      context,
    );
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Filtros',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Filtros guardados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          _buildSavedFilters(context),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Categorías',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/filters/saved'),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategoryFilters(context, logic),
          const SizedBox(height: 24),
          const Text(
            'Rango de fechas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          _buildDateRangeSelector(context, logic),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, logic.getFilters());
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('Aplicar filtros'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              logic.clearFilters();
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedFilters(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: <Widget>[
        _buildSavedFilterChip(context, 'Gastos de Comida'),
        const SizedBox(width: 8),
        _buildSavedFilterChip(context, 'Transporte'),
        const SizedBox(width: 8),
        _buildSavedFilterChip(context, 'Entretenimiento'),
      ],
    ),
  );

  Widget _buildSavedFilterChip(BuildContext context, String label) =>
      FilterChip(
        label: Text(label),
        onSelected: (bool selected) {
          // Implementar lógica para aplicar filtro guardado
        },
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );

  Widget _buildCategoryFilters(
    BuildContext context,
    TransactionFiltersLogic logic,
  ) {
    final List<String> categories = <String>[
      'Comida',
      'Transporte',
      'Entretenimiento',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          categories
              .map(
                (String category) => FilterChip(
                  selected: logic.selectedCategories.contains(category),
                  label: Text(category),
                  onSelected:
                      (bool selected) =>
                          logic.selectCategory(category, isSelected: selected),
                  backgroundColor: Colors.grey[100],
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildDateRangeSelector(
    BuildContext context,
    TransactionFiltersLogic logic,
  ) => Row(
    children: <Widget>[
      Expanded(
        child: TextFormField(
          readOnly: true,
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: logic.startDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              logic.setStartDate(picked);
            }
          },
          decoration: InputDecoration(
            hintText: 'Desde',
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          controller: TextEditingController(
            text:
                logic.startDate != null
                    ? '${logic.startDate!.day}/${logic.startDate!.month}/${logic.startDate!.year}'
                    : '',
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: TextFormField(
          readOnly: true,
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: logic.endDate ?? DateTime.now(),
              firstDate: logic.startDate ?? DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              logic.setEndDate(picked);
            }
          },
          decoration: InputDecoration(
            hintText: 'Hasta',
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          controller: TextEditingController(
            text:
                logic.endDate != null
                    ? '${logic.endDate!.day}/${logic.endDate!.month}/${logic.endDate!.year}'
                    : '',
          ),
        ),
      ),
    ],
  );
}
