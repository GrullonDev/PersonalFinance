import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/parsers/quick_entry_parser.dart';

/// Widget de entrada rápida de transacciones.
///
/// Soporta:
///   "+500 salario"  → income, 500, "salario"
///   "-80 comida"    → expense, 80, "comida"
///   "120 taxi"      → expense, 120, "taxi" (sin signo = gasto)
///
/// Validaciones:
///   - Input vacío se ignora
///   - Texto sin número muestra error
///   - Monto ≤ 0 muestra error
///
/// Feedback visual:
///   - SnackBar con tipo + monto + nota tras guardar
///   - Animación del botón send
///   - Auto limpieza del input + unfocus
class QuickEntryInput extends StatefulWidget {
  final void Function(double amount, TransactionType type, String note) onAdd;

  const QuickEntryInput({super.key, required this.onAdd});

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
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final parsed = _parser.parse(input);

    if (parsed == null) {
      setState(() => _errorText = 'Formato inválido. Ej: -80 comida');
      HapticFeedback.lightImpact();
      return;
    }

    // Limpiar error previo
    setState(() => _errorText = null);

    // Animación del botón
    _animController.forward().then((_) => _animController.reverse());

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Disparar callback
    widget.onAdd(parsed.amount, parsed.type, parsed.note);

    // Feedback visual — SnackBar
    _showFeedback(parsed);

    // Auto limpiar
    _controller.clear();
    _focusNode.unfocus();
  }

  void _showFeedback(ParsedEntry parsed) {
    final isIncome = parsed.type == TransactionType.income;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${isIncome ? '+' : '-'}\$${parsed.amount.toStringAsFixed(2)}  •  ${parsed.note}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.check_circle_outline, color: Colors.white70, size: 18),
          ],
        ),
        backgroundColor: isIncome
            ? const Color(0xFF2E7D32) // green 800
            : const Color(0xFFC62828), // red 800
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
                    prefixIcon: const Icon(Icons.flash_on, color: Colors.amber),
                    hintText: 'Ej: -80 comida, +500 salario',
                    errorText: _errorText,
                    errorMaxLines: 2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.secondaryHeaderColor.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (_) {
                    // Limpiar error al editar
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
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _submit,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              'Usa "-" para gastos y "+" para ingresos  •  Sin signo = gasto',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
