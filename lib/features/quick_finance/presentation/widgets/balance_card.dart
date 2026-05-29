import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/core/services/haptic_feedback_service.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/utils/currency_helper.dart';

enum _Period { today, week, month }

class BalanceCard extends StatefulWidget {
  final List<TransactionEntity> transactions;
  final bool forceHidden;

  const BalanceCard({
    required this.transactions,
    super.key,
    this.forceHidden = false,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _hidden = false;
  _Period _period = _Period.today;

  void _toggleVisibility() {
    if (widget.forceHidden) return;
    HapticFeedbackService.selection();
    setState(() => _hidden = !_hidden);
  }

  List<TransactionEntity> get _filtered {
    final now = DateTime.now();
    return widget.transactions.where((t) {
      if (t.deletedAt != null) return false;
      switch (_period) {
        case _Period.today:
          return t.createdAt.year == now.year &&
              t.createdAt.month == now.month &&
              t.createdAt.day == now.day;
        case _Period.week:
          final weekStart = DateTime(
            now.year,
            now.month,
            now.day - (now.weekday - 1),
          );
          return !t.createdAt.isBefore(weekStart);
        case _Period.month:
          return t.createdAt.year == now.year && t.createdAt.month == now.month;
      }
    }).toList();
  }

  double get _income => _filtered
      .where((t) => t.type == TransactionType.income)
      .fold(0, (s, t) => s + t.amount);

  double get _expenses => _filtered
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (s, t) => s + t.amount);

  double get _balance => _income - _expenses;

  String get _insightText {
    final expenses = _expenses;
    final income = _income;
    final balance = _balance;
    final effectiveHidden = widget.forceHidden || _hidden;

    switch (_period) {
      case _Period.today:
        if (expenses == 0 && income == 0) return 'Sin movimientos hoy';
        if (expenses == 0) return 'Sin gastos hoy';
        if (effectiveHidden) return 'Tienes gastos registrados hoy';
        return 'Gastaste ${CurrencyHelper.format(expenses)} hoy';
      case _Period.week:
        if (expenses == 0 && income == 0) return 'Sin movimientos esta semana';
        if (expenses == 0) return 'Sin gastos esta semana';
        if (effectiveHidden) return 'Tienes gastos esta semana';
        return 'Gastaste ${CurrencyHelper.format(expenses)} esta semana';
      case _Period.month:
        if (expenses == 0 && income == 0) return 'Sin movimientos este mes';
        if (balance < 0) return 'Balance negativo este mes';
        if (balance == 0) return 'Sin ganancias ni pérdidas';
        if (effectiveHidden) return 'Balance positivo este mes';
        return 'Ahorraste ${CurrencyHelper.format(balance)} este mes';
    }
  }

  Color get _insightColor {
    switch (_period) {
      case _Period.today:
      case _Period.week:
        return _expenses > 0 ? const Color(0xFFFF9500) : Colors.grey.shade400;
      case _Period.month:
        return _balance < 0 ? const Color(0xFFFF3B30) : Colors.grey.shade400;
    }
  }

  IconData get _insightIcon {
    switch (_period) {
      case _Period.today:
      case _Period.week:
        return _expenses > 0
            ? Icons.info_outline_rounded
            : Icons.check_circle_outline_rounded;
      case _Period.month:
        return _balance < 0
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline_rounded;
    }
  }

  // Returns the top expense category and its share (%), or null if not enough data.
  ({String label, int pct})? get _topCategory {
    if (widget.forceHidden || _hidden) return null;
    final expenses =
        _filtered.where((t) => t.type == TransactionType.expense).toList();
    if (expenses.length < 2) return null;

    final catAmounts = <String, double>{};
    for (final t in expenses) {
      final cat = _inferCat(t);
      catAmounts[cat] = (catAmounts[cat] ?? 0) + t.amount;
    }
    final total = catAmounts.values.fold<double>(0, (s, v) => s + v);
    if (total == 0) return null;

    final top = catAmounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    final pct = (top.value / total * 100).round();
    if (pct < 30) return null;

    final label = top.key[0].toUpperCase() + top.key.substring(1);
    return (label: label, pct: pct);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHidden = widget.forceHidden || _hidden;
    final accent = Theme.of(context).primaryColor;
    final balance = _balance;
    final balanceColor =
        effectiveHidden
            ? Colors.grey.shade700
            : (balance >= 0
                ? const Color(0xFF34C759)
                : const Color(0xFFFF3B30));

    final periodLabel = switch (_period) {
      _Period.today => 'hoy',
      _Period.week => 'esta semana',
      _Period.month => 'este mes',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector + visibility toggle
          Row(
            children: [
              _PeriodSelector(
                selected: _period,
                accent: accent,
                onChanged: (p) => setState(() => _period = p),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleVisibility,
                child: Icon(
                  widget.forceHidden
                      ? Icons.privacy_tip_outlined
                      : effectiveHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'Balance $periodLabel',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              key: ValueKey('$effectiveHidden$_period$balance'),
              effectiveHidden ? '••••' : CurrencyHelper.format(balance),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: balanceColor,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Insight accionable
          Row(
            children: [
              Icon(_insightIcon, size: 13, color: _insightColor),
              const SizedBox(width: 5),
              Text(
                _insightText,
                style: TextStyle(fontSize: 12, color: _insightColor),
              ),
            ],
          ),
          if (widget.forceHidden) ...[
            const SizedBox(height: 10),
            Text(
              'Private mode activo: los montos permanecen ocultos en toda la app.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 16),

          // Fila ingresos / gastos
          Row(
            children: [
              Expanded(
                child: _StatRow(
                  icon: Icons.arrow_upward_rounded,
                  iconBg: const Color(0xFFE8F9EE),
                  iconColor: const Color(0xFF34C759),
                  label: 'Ingresos',
                  amount: _income,
                  hidden: effectiveHidden,
                ),
              ),
              Expanded(
                child: _StatRow(
                  icon: Icons.arrow_downward_rounded,
                  iconBg: const Color(0xFFFFEEED),
                  iconColor: const Color(0xFFFF3B30),
                  label: 'Gastos',
                  amount: _expenses,
                  hidden: effectiveHidden,
                  alignRight: true,
                ),
              ),
            ],
          ),

          // Top category (only when data is meaningful)
          if (_topCategory case final top?) ...[
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 13,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 5),
                Text(
                  'Mayor gasto: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                Text(
                  '${top.label} (${top.pct}%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Category inference (for top-category computation) ────────────────────────

bool _kw(String text, List<String> kw) => kw.any(text.contains);

String _inferCat(TransactionEntity t) {
  final text = '${t.note} ${t.categoryId ?? ''}'.toLowerCase();
  if (_kw(text, [
    'comida',
    'almuerzo',
    'cena',
    'café',
    'cafe',
    'restaurante',
    'super',
    'mercado',
  ])) {
    return 'comida';
  }
  if (_kw(text, [
    'transporte',
    'taxi',
    'uber',
    'bus',
    'metro',
    'gasolina',
    'coche',
  ])) {
    return 'transporte';
  }
  if (_kw(text, ['venta', 'ventas', 'negocio', 'comercio', 'producto'])) {
    return 'negocio';
  }

  if (_kw(text, [
    'servicio',
    'luz',
    'agua',
    'gas',
    'internet',
    'renta',
    'alquiler',
  ])) {
    return 'servicios';
  }
  if (_kw(text, ['compra', 'tienda', 'ropa', 'amazon', 'mall', 'shopping'])) {
    return 'compras';
  }
  if (_kw(text, ['salud', 'medico', 'farmacia', 'gym', 'deporte'])) {
    return 'salud';
  }
  if (_kw(text, ['cine', 'netflix', 'spotify', 'streaming'])) {
    return 'entretenimiento';
  }
  return t.categoryId ?? 'otros';
}

// ── Period selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _Period selected;
  final Color accent;
  final ValueChanged<_Period> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children:
          _Period.values.map((p) {
            final isSelected = p == selected;
            final label = switch (p) {
              _Period.today => 'Hoy',
              _Period.week => 'Semana',
              _Period.month => 'Mes',
            };
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(p);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                          : [],
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? accent : Colors.grey.shade500,
                  ),
                ),
              ),
            );
          }).toList(),
    ),
  );
}

// ── Stat row ──────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final double amount;
  final bool hidden;
  final bool alignRight;

  const _StatRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.amount,
    required this.hidden,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 13),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            Text(
              hidden ? '••' : CurrencyHelper.format(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ],
    );

    return alignRight
        ? Align(alignment: Alignment.centerRight, child: content)
        : content;
  }
}
