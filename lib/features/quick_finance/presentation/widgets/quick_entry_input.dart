import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/parsers/quick_entry_parser.dart';

/// Widget de entrada rápida de transacciones.
///
/// Parsea el texto localmente para dar feedback inmediato (error inline
/// y SnackBar de confirmación). Una vez que el parse es exitoso, delega
/// el guardado al BLoC a través de [onSubmit] con el texto crudo, de modo
/// que el BLoC es la fuente autoritativa para persistir la transacción.
///
/// Soporta:
///   "-80 comida"           → expense, 80.0, "comida"
///   "+500 salario"         → income,  500.0, "salario"
///   "120 taxi #transporte" → expense, 120.0, "taxi", category:"transporte"
///   "-35,50 almuerzo"      → expense, 35.5, "almuerzo"
///   "$50 grocery"          → expense, 50.0, "grocery"
class QuickEntryInput extends StatefulWidget {
  /// Llamado con el texto crudo cuando el parse local es exitoso.
  /// El BLoC lo re-parsea con [QuickEntryParser] para persistir.
  final void Function(String rawInput) onSubmit;

  const QuickEntryInput({super.key, required this.onSubmit});

  @override
  State<QuickEntryInput> createState() => _QuickEntryInputState();
}

class _QuickEntryInputState extends State<QuickEntryInput>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  static const _parser = QuickEntryParser();

  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  String? _errorText;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    // Parse local para feedback inmediato antes de enviar al BLoC
    final result = _parser.parse(raw);

    switch (result) {
      case ParseFailure(:final reason):
        setState(() => _errorText = reason);
        HapticFeedback.lightImpact();

      case ParseSuccess(:final entry):
        setState(() => _errorText = null);
        _animController.forward().then((_) => _animController.reverse());
        HapticFeedback.mediumImpact();

        // El texto crudo llega al BLoC que lo persiste
        widget.onSubmit(raw);

        _showFeedback(entry);
        _controller.clear();
        _focusNode.unfocus();
    }
  }

  void _showFeedback(ParsedEntry entry) {
    final isIncome = entry.type == TransactionType.income;
    final categoryLabel =
        entry.category != null ? '  •  #${entry.category}' : '';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isIncome
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${isIncome ? '+' : '-'}\$${entry.amount.toStringAsFixed(2)}'
                '  •  ${entry.note}$categoryLabel',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
        backgroundColor:
            isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                  focusNode: _focusNode,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.flash_on, color: Colors.amber),
                    hintText: 'Ej: -80 comida  /  +500 salario #trabajo',
                    errorText: _errorText,
                    errorMaxLines: 2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        theme.secondaryHeaderColor.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 12),
              ScaleTransition(
                scale: _scaleAnimation,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.primaryColor,
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _submit,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '"-" gastos  •  "+" ingresos  •  sin signo = gasto  •  #categoría',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
