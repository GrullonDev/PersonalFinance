import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_finance/features/categories/domain/entities/category.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/features/categories/presentation/providers/categories_provider.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/presentation/bloc/transactions_bloc.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _tipo = 'gasto';
  int? _categoriaId;
  DateTime _fecha = DateTime.now();
  bool _recurrente = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final CategoriesProvider cats = context.read<CategoriesProvider>();
      if (cats.categories.isEmpty) cats.loadCategories();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
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

            Row(
              children: <Widget>[
                Expanded(
                  child: _TransactionTypeButton(
                    label: 'Gasto',
                    icon: Icons.arrow_downward,
                    isSelected: _tipo == 'gasto',
                    onTap: () => setState(() => _tipo = 'gasto'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TransactionTypeButton(
                    label: 'Ingreso',
                    icon: Icons.arrow_upward,
                    isSelected: _tipo == 'ingreso',
                    onTap: () => setState(() => _tipo = 'ingreso'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) return 'Ingrese un monto';
                if (double.tryParse(value) == null) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            Consumer<CategoriesProvider>(
              builder:
                  (BuildContext context, CategoriesProvider cats, _) =>
                      DropdownButtonFormField<int>(
                        initialValue: _categoriaId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        hint: const Text('Selecciona una categoría'),
                        items:
                            cats.categories
                                .map(
                                  (Category c) => DropdownMenuItem<int>(
                                    value: c.id,
                                    child: Text(c.nombre),
                                  ),
                                )
                                .toList(),
                        onChanged: (int? v) => setState(() => _categoriaId = v),
                        validator:
                            (int? v) =>
                                v == null ? 'Selecciona una categoría' : null,
                      ),
            ),
            const SizedBox(height: 16),

            _DatePickerField(
              selectedDate: _fecha,
              onDateSelected: (DateTime d) => setState(() => _fecha = d),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Transacción recurrente'),
              value: _recurrente,
              onChanged: (bool value) => setState(() => _recurrente = value),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final TransactionsBloc bloc = context.read<TransactionsBloc>();
                final TransactionBackend payload = TransactionBackend(
                  tipo: _tipo,
                  monto:
                      (double.parse(_amountController.text.trim())).toString(),
                  descripcion: _descriptionController.text.trim(),
                  fecha: _fecha,
                  categoriaId: _categoriaId ?? 0,
                  esRecurrente: _recurrente,
                );
                bloc.add(TransactionCreate(payload));
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Guardar Transacción',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
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

// removed old local selector in favor of CategoriesProvider

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
