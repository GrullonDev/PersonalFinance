import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';

class AddIncomeModal extends StatefulWidget {
  const AddIncomeModal({super.key});

  @override
  State<AddIncomeModal> createState() => _AddIncomeModalState();
}

class _AddIncomeModalState extends State<AddIncomeModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final DashboardLogic logic = context.read<DashboardLogic>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Título del ingreso'),
          ),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monto'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                setState(() => _selectedDate = pickedDate);
              }
            },
            child: Text(
              'Seleccionar fecha: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Llamar al método addIncome
              logic.addIncome(
                _titleController.text,
                _amountController.text,
                _selectedDate,
              );

              Navigator.pop(context); // Cierra el modal
            },
            child: const Text('Agregar Ingreso'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
