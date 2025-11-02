import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_finance/features/dashboard/presentation/providers/dashboard_logic.dart';
import 'package:personal_finance/features/navigation/navigation_provider.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:provider/provider.dart';

/// Modal para agregar un nuevo ingreso.
/// Permite ingresar título, monto, categoría y fecha del ingreso.
class AddIncomeModal extends StatefulWidget {
  const AddIncomeModal({super.key});

  @override
  State<AddIncomeModal> createState() => _AddIncomeModalState();
}

class _AddIncomeModalState extends State<AddIncomeModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Salario';

  final List<String> _categorySuggestions = <String>[
    'Salario',
    'Venta',
    'Reembolso',
    'Inversión',
    'Otro',
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
                fieldViewBuilder:
                    (
                      BuildContext context,
                      TextEditingController controller,
                      FocusNode focusNode,
                      _,
                    ) => TextFormField(
                      controller: _titleController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Título del ingreso',
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
                initialValue: _selectedCategory,
                items:
                    _categorySuggestions
                        .map(
                          (String e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
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
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await logic.addIncome(
                        _titleController.text,
                        _amountController.text,
                        _selectedDate,
                      );
                      // Limpiar campos después de agregar
                      _titleController.clear();
                      _amountController.clear();
                      setState(() {
                        _selectedDate = DateTime.now();
                        _selectedCategory = 'Salario';
                      });
                      if (!mounted) return;

                      // Navegar al dashboard después de agregar el ingreso
                      Navigator.of(context).pop();
                      Provider.of<NavigationProvider>(
                        context,
                        listen: false,
                      ).setIndex(0);
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: Text(AppLocalizations.of(context)!.addIncome),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
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
