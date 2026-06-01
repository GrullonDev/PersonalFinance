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

    final periodLabel = switch (_period) {
      _Period.today => 'hoy',
      _Period.week => 'esta semana',
      _Period.month => 'este mes',
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient header (premium card style) ──────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(accent, Colors.black, 0.08)!,
                    Color.lerp(accent, Colors.black, 0.38)!,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector + visibility toggle
                  Row(
                    children: [
                      _PeriodSelector(
                        selected: _period,
                        onChanged: (p) => setState(() => _period = p),
                        onDark: true,
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
                          color: Colors.white.withValues(alpha: 0.75),
                          size: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Text(
                    'Balance $periodLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      key: ValueKey('$effectiveHidden$_period$balance'),
                      effectiveHidden ? '••••' : CurrencyHelper.format(balance),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: effectiveHidden
                            ? Colors.white.withValues(alpha: 0.9)
                            : balance >= 0
                            ? Colors.white
                            : const Color(0xFFFFAFAF),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Insight como pill de vidrio (estilo onboarding)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _insightIcon,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _insightText,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (widget.forceHidden) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Private mode: montos ocultos en toda la app.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Surface footer ────────────────────────────────────────────
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  if (!effectiveHidden && _income > 0) ...[
                    const SizedBox(height: 12),
                    _RatioBar(income: _income, expenses: _expenses),
                  ],

                  if (_topCategory case final top?) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category inference ────────────────────────────────────────────────────────

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

// ── Expense / income ratio bar ────────────────────────────────────────────────

class _RatioBar extends StatelessWidget {
  final double income;
  final double expenses;

  const _RatioBar({required this.income, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final ratio = (expenses / income).clamp(0.0, 1.0);
    final Color barColor = ratio > 0.9
        ? const Color(0xFFFF3B30)
        : ratio > 0.7
        ? const Color(0xFFFF9500)
        : const Color(0xFF34C759);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gastos vs ingresos',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            Text(
              '${(ratio * 100).round()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

// ── Period selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;
  final bool onDark;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: onDark
          ? Colors.white.withValues(alpha: 0.15)
          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: _Period.values.map((p) {
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? (onDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : Theme.of(context).colorScheme.surface)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              boxShadow: isSelected && !onDark
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
                color: isSelected
                    ? (onDark ? Colors.white : Theme.of(context).primaryColor)
                    : (onDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.grey.shade500),
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
                color: Theme.of(context).colorScheme.onSurface,
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
