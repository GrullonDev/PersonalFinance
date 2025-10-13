import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_finance/features/transactions/logic/transaction_logic.dart';
import 'package:personal_finance/features/transactions/models/transaction_model.dart';
import 'package:provider/provider.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => TransactionLogic(),
    child: Consumer<TransactionLogic>(
      builder:
          (BuildContext context, TransactionLogic logic, _) => GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Header with drag handle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Transaction type selector
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _TransactionTypeButton(
                            label: 'Gasto',
                            icon: Icons.arrow_downward,
                            isSelected:
                                logic.currentTransaction?.type ==
                                TransactionType.expense,
                            onTap:
                                () => logic.updateTransactionType(
                                  TransactionType.expense,
                                ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _TransactionTypeButton(
                            label: 'Ingreso',
                            icon: Icons.arrow_upward,
                            isSelected:
                                logic.currentTransaction?.type ==
                                TransactionType.income,
                            onTap:
                                () => logic.updateTransactionType(
                                  TransactionType.income,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Amount field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (String value) {
                        if (value.isNotEmpty) {
                          logic.updateAmount(double.parse(value));
                        }
                      },
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese un monto';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Ingrese un monto válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category selector
                    _CategorySelector(
                      onCategorySelected: logic.updateCategory,
                      selectedCategory:
                          logic.currentTransaction?.category ?? '',
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    _DatePickerField(
                      selectedDate:
                          logic.currentTransaction?.date ?? DateTime.now(),
                      onDateSelected: logic.updateDate,
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'Ej: Almuerzo con amigos',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 2,
                      onChanged: logic.updateDescription,
                    ),
                    const SizedBox(height: 16),

                    // Recurring transaction switch
                    SwitchListTile(
                      title: const Text('Transacción recurrente'),
                      value: logic.currentTransaction?.isRecurring ?? false,
                      onChanged: logic.updateIsRecurring,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    ElevatedButton(
                      onPressed:
                          logic.isLoading
                              ? null
                              : () {
                                if (_formKey.currentState!.validate()) {
                                  logic.saveTransaction().then((_) {
                                    Navigator.of(context).pop();
                                  });
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          logic.isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Guardar Transacción',
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    ),
  );
}

class _TransactionTypeButton extends StatelessWidget {
  const _TransactionTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color:
        isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              color:
                  isSelected ? Colors.white : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.onCategorySelected,
    required this.selectedCategory,
  });

  final void Function(String) onCategorySelected;
  final String selectedCategory;

  static const List<String> _categories = <String>[
    'Comida',
    'Transporte',
    'Hogar',
    'Entretenimiento',
    'Salud',
    'Educación',
    'Ropa',
    'Otros',
  ];

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: 'Categoría',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedCategory.isEmpty ? null : selectedCategory,
        hint: const Text('Selecciona una categoría'),
        isExpanded: true,
        items:
            _categories
                .map(
                  (String category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
        onChanged: (String? value) {
          if (value != null) {
            onCategorySelected(value);
          }
        },
      ),
    ),
  );
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        onDateSelected(picked);
      }
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Fecha',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      child: Text(
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
      ),
    ),
  );
}
