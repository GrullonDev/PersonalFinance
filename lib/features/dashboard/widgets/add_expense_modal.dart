import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:provider/provider.dart';

class AddExpenseModal extends StatefulWidget {
  const AddExpenseModal({super.key});

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Otros';

  final List<String> _categorySuggestions = <String>[
    'Alimentación',
    'Transporte',
    'Hogar',
    'Entretenimiento',
    'Compras',
    'Salud',
    'Créditos',
    'Otros',
  ];

  @override
  Widget build(BuildContext context) {
    final DashboardLogic logic = context.read<DashboardLogic>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  if (value.text.isEmpty) return const Iterable<String>.empty();
                  return _categorySuggestions.where(
                    (String option) =>
                        option.toLowerCase().contains(value.text.toLowerCase()),
                  );
                },
                onSelected: (String value) {
                  _titleController.text = value;
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController controller,
                  FocusNode focusNode,
                  _,
                ) => TextFormField(
                    controller: _titleController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Título del gasto',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (String? value) =>
                            (value == null || value.isEmpty)
                                ? 'Requerido'
                                : null,
                  ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                  prefixText: 'Q ',
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) return 'Monto requerido';
                  final double? amount = double.tryParse(value);
                  if (amount == null || amount <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items:
                    _categorySuggestions
                        .map(
                          (String e) =>
                              DropdownMenuItem<String>(value: e, child: Text(e)),
                        )
                        .toList(),
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Text(
                    'Fecha: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
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
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Cambiar'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      logic.addExpense(
                        _titleController.text,
                        _amountController.text,
                        _selectedDate,
                        _selectedCategory,
                      );
                      // Limpiar campos después de agregar
                      _titleController.clear();
                      _amountController.clear();
                      setState(() {
                        _selectedDate = DateTime.now();
                        _selectedCategory = 'Otros';
                      });
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: Text(AppLocalizations.of(context)!.addExpense),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    /* AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(16.0),
      curve: Curves.easeInOut,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nuevo Gasto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del gasto',
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Campo obligatorio'
                            : null,
              ),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monto'),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  return parsed == null || parsed <= 0
                      ? 'Monto inválido'
                      : null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items:
                    <String>[
                          'Alimentación',
                          'Transporte',
                          'Hogar',
                          'Entretenimiento',
                          'Compras',
                          'Salud',
                          'Créditos',
                          'Otros',
                        ]
                        .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Text(
                  'Fecha: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    logic.addExpense(
                      _titleController.text,
                      _amountController.text,
                      _selectedDate,
                      _selectedCategory, // para futura integración
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text(AppLocalizations.of(context)!.addExpense),
              ),
            ],
          ),
        ),
      ),
    ); */
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
