import 'package:flutter/material.dart';
import 'package:personal_finance/utils/currency_helper.dart';
import 'package:personal_finance/utils/app_localization.dart';
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
  late final TextEditingController _categoryController;
  bool _editing = false;
  bool _invalidAmount = false;

  bool get _requiresSettlement => widget.capture.currency != null &&
      widget.capture.currency != CurrencyHelper.code && !widget.capture.isSample;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.capture.note);
    _amountController = TextEditingController(
      text: _requiresSettlement || widget.capture.needsAmount ? '' : widget.capture.amount.toStringAsFixed(2),
    );
    _categoryController = TextEditingController(text: widget.capture.category);
    _editing = widget.capture.needsAmount || _requiresSettlement;
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final editedNote = _noteController.text.trim();
    if (widget.capture.isSample) return;
    final editedCategory = _categoryController.text.trim();
    final parsedAmount = double.tryParse(_amountController.text.trim());
    if (parsedAmount == null || !parsedAmount.isFinite || parsedAmount <= 0) {
      setState(() => _invalidAmount = true);
      return;
    }
    final editedAmount =
        parsedAmount != widget.capture.amount ? parsedAmount : null;
    context.read<QuickFinanceBloc>().add(
      AutoCaptureConfirmed(
        widget.capture,
        editedNote: editedNote != widget.capture.note ? editedNote : null,
        editedCategoryId:
            editedCategory != (widget.capture.category ?? '')
                ? editedCategory
                : null,
        editedAmount: editedAmount,
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

    String tr(String key) => AppLocalizations.captureText(context, key);
    return SingleChildScrollView(
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
            tr('captureDetected'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.capture.isSample) Text(tr('captureSampleNote')),
          if (_requiresSettlement)
            Text('${widget.capture.amount.toStringAsFixed(2)} ${widget.capture.currency}. ${tr('captureSettlement')} ${CurrencyHelper.code}.'),
          if (!_editing) ...[
            Text([_amountController.text, if (widget.capture.currency != null) widget.capture.currency!].join(' '), style: theme.textTheme.titleLarge),
            Text(widget.capture.note),
            if (widget.capture.category != null) Text(widget.capture.category!),
            if (!widget.capture.isSample)
              TextButton.icon(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_outlined),
                label: Text(tr('captureEdit')),
              ),
          ] else ...[
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                errorText: _invalidAmount ? tr('captureInvalid') : null,
                labelText: tr('captureAmount'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: tr('captureNote'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: tr('captureCategory'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _dismiss,
                  child: Text(tr('captureDismiss')),
                ),
              ),
              if (!widget.capture.isSample) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm,
                    child: Text(tr('captureConfirm')),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
