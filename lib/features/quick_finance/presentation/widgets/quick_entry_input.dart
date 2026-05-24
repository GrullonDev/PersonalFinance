import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/domain/parsers/quick_entry_parser.dart';

class QuickEntryInput extends StatefulWidget {
  final void Function(String rawInput) onSubmit;

  const QuickEntryInput({required this.onSubmit, super.key});

  @override
  State<QuickEntryInput> createState() => QuickEntryInputState();
}

/// State is intentionally public so a parent can call [prefill] via GlobalKey.
class QuickEntryInputState extends State<QuickEntryInput>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  static const _parser = QuickEntryParser();

  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  String? _errorText;

  static const _categoryLabels = [
    'Comida',
    'Transporte',
    'Salario',
    'Servicios',
    'Compras',
    'Salud',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1, end: 0.85).animate(
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

  // Called by parent via GlobalKey to pre-fill from empty-state chips.
  void prefill(String text) {
    setState(() => _errorText = null);
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _focusNode.requestFocus();
  }

  void _applySign(bool isExpense) {
    HapticFeedback.selectionClick();
    final text = _controller.text;
    final sign = isExpense ? '-' : '+';
    final opposite = isExpense ? '+' : '-';
    final newText = text.startsWith(opposite)
        ? sign + text.substring(1)
        : text.startsWith(sign)
            ? text
            : sign + text;
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newText.length);
    if (_errorText != null) setState(() => _errorText = null);
    _focusNode.requestFocus();
  }

  void _applyCategory(String keyword) {
    HapticFeedback.selectionClick();
    final current = _controller.text.trimRight();
    if (!current.toLowerCase().contains(keyword.toLowerCase())) {
      final newText = current.isEmpty ? keyword : '$current $keyword';
      _controller.text = newText;
      _controller.selection =
          TextSelection.collapsed(offset: newText.length);
    }
    if (_errorText != null) setState(() => _errorText = null);
    _focusNode.requestFocus();
  }

  void _submit() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    switch (_parser.parse(raw)) {
      case ParseFailure(:final reason):
        setState(() => _errorText = reason);
        HapticFeedback.lightImpact();

      case ParseSuccess(:final entry):
        setState(() => _errorText = null);
        _animController.forward().then((_) => _animController.reverse());
        HapticFeedback.mediumImpact();
        widget.onSubmit(raw);
        _showFeedback(entry);
        _controller.clear();
        _focusNode.unfocus();
    }
  }

  void _showFeedback(ParsedEntry entry) {
    final isIncome = entry.type == TransactionType.income;
    final cat = entry.category != null ? '  •  #${entry.category}' : '';
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
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
                  '  •  ${entry.note}$cat',
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // ── Text field with integrated send button ──────────────────────────
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.send,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[<>]')),
              LengthLimitingTextInputFormatter(100),
            ],
            decoration: InputDecoration(
              hintText: '-80 comida',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              errorText: _errorText,
              errorMaxLines: 2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF2F3F5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: ScaleTransition(
                scale: _scaleAnim,
                child: GestureDetector(
                  onTap: _submit,
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 10),

          // ── Type chips ──────────────────────────────────────────────────────
          Row(
            children: [
              _TypeChip(
                label: '− Gasto',
                color: const Color(0xFFFF3B30),
                onTap: () => _applySign(true),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: '+ Ingreso',
                color: const Color(0xFF34C759),
                onTap: () => _applySign(false),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Category chips (scrollable) ─────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final label in _categoryLabels) ...[
                  _CategoryEntryChip(
                    label: label,
                    onTap: () => _applyCategory(label.toLowerCase()),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Type chip ─────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      );
}

// ── Category entry chip ───────────────────────────────────────────────────────

class _CategoryEntryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CategoryEntryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
}
