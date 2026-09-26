import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/auto_capture/data/auto_capture_service.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_event.dart';

class AutoCaptureBottomSheet extends StatefulWidget {
  const AutoCaptureBottomSheet({super.key, required this.capture});

  final AutoCapturedTransaction capture;

  @override
  State<AutoCaptureBottomSheet> createState() => _AutoCaptureBottomSheetState();
}

class _AutoCaptureBottomSheetState extends State<AutoCaptureBottomSheet> {
  late final TextEditingController _noteController;
  late final TextEditingController _amountController;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.capture.note);
    _amountController = TextEditingController(
      text: widget.capture.amount.toStringAsFixed(2),
    );
    _selectedCategory = widget.capture.category;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final editedNote = _noteController.text.trim();
    final editedCategory = _selectedCategory;
    context.read<QuickFinanceBloc>().add(
      AutoCaptureConfirmed(
        widget.capture,
        editedNote: editedNote != widget.capture.note ? editedNote : null,
        editedCategoryId:
            editedCategory != widget.capture.category ? editedCategory : null,
      ),
    );
    Navigator.of(context).pop();
  }

  void _dismiss() {
    context.read<QuickFinanceBloc>().add(AutoCaptureDismissed(widget.capture));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            label: Text(
              widget.capture.sourceLabel,
              style: theme.textTheme.labelSmall,
            ),
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
          const SizedBox(height: 8),
          Text(
            'Pago detectado',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
            ),
          ),
          if (_selectedCategory != null) ...[
            const SizedBox(height: 8),
            Text(
              'Categoría: $_selectedCategory',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _dismiss,
                  child: const Text('Descartar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirm,
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
