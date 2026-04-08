import 'package:flutter/material.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/parsers/quick_entry_parser.dart';

class QuickEntryInput extends StatefulWidget {
  final void Function(double amount, TransactionType type, String note) onAdd;

  const QuickEntryInput({super.key, required this.onAdd});

  @override
  State<QuickEntryInput> createState() => _QuickEntryInputState();
}

class _QuickEntryInputState extends State<QuickEntryInput> {
  final TextEditingController _controller = TextEditingController();
  static const _parser = QuickEntryParser();

  void _submit() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final parsed = _parser.parse(input);
    if (parsed != null) {
      widget.onAdd(parsed.amount, parsed.type, parsed.note);
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.flash_on, color: Colors.amber),
                    hintText: 'Ej: -35 cena',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).secondaryHeaderColor.withValues(alpha: 0.1),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
              'Usa "-" para gastos y "+" para ingresos (ej: -5.0 café)',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
