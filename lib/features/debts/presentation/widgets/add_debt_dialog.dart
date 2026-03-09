import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/core/services/device_service.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'package:personal_finance/features/debts/presentation/bloc/debts_bloc.dart';
import 'package:personal_finance/features/debts/presentation/bloc/debts_event.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:uuid/uuid.dart';

class AddDebtDialog extends StatefulWidget {
  const AddDebtDialog({super.key});

  @override
  State<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<AddDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _balanceController = TextEditingController();
  final _interestController = TextEditingController();
  final _minimumController = TextEditingController();

  DateTime? _nextPaymentDate;

  void _submit() {
    if (_formKey.currentState!.validate() && _nextPaymentDate != null) {
      final name = _nameController.text.trim();
      final amount = double.parse(_amountController.text.trim());
      final balance = double.parse(_balanceController.text.trim());
      final interest = double.parse(_interestController.text.trim());
      final minimum = double.parse(_minimumController.text.trim());

      final newDebt = Debt(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deviceId: getIt<DeviceService>().deviceId,
        version: 1,
        name: name,
        originalAmount: amount,
        currentBalance: balance,
        interestRate: interest,
        minimumPayment: minimum,
        nextPaymentDate: _nextPaymentDate!,
      );

      context.read<DebtsBloc>().add(DebtCreate(newDebt));
      Navigator.of(context).pop();
    } else if (_nextPaymentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una fecha de pago.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Agregar Nueva Deuda',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Deuda (ej. Tarjeta de Crédito)',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto Original (Deuda Inicial)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (double.tryParse(value) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saldo Pendiente (Actual)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (double.tryParse(value) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tasa de Interés Anual (%)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (double.tryParse(value) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minimumController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pago Mínimo Requerido',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (double.tryParse(value) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(
                      const Duration(days: 365 * 10),
                    ),
                  );
                  if (date != null) {
                    setState(() {
                      _nextPaymentDate = date;
                    });
                  }
                },
                icon: const Icon(Icons.date_range),
                label: Text(
                  _nextPaymentDate == null
                      ? 'Seleccionar Fecha de Pago'
                      : 'Pago: ${DateFormat.MMMd().format(_nextPaymentDate!)}',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
