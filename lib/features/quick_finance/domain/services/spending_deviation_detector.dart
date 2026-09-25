import 'package:equatable/equatable.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';

/// Tipos de desvío de dinero que la app sabe detectar.
enum SpendingDeviationType {
  /// Este mes se gasta más de lo que se ingresa.
  spendingAboveIncome,

  /// Una categoría (o concepto) supera claramente su promedio histórico.
  categorySpike,

  /// Al ritmo actual el gasto del mes terminará muy por encima del promedio.
  monthlyPaceAboveAverage,

  /// Muchos gastos pequeños que juntos suman una parte importante del mes.
  antExpenses,

  /// Un solo concepto se lleva la mayor parte del gasto del mes.
  categoryConcentration,
}

/// Un desvío detectado, con un mensaje educativo listo para notificar.
class SpendingDeviation extends Equatable {
  /// Identificador estable por mes: evita notificar dos veces lo mismo.
  final String key;
  final SpendingDeviationType type;

  /// 3 = crítico, 2 = importante, 1 = informativo.
  final int severity;
  final String title;
  final String body;

  /// Concepto afectado (categoría o nota), si aplica.
  final String? group;

  const SpendingDeviation({
    required this.key,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    this.group,
  });

  @override
  List<Object?> get props => [key, type, severity, title, body, group];
}

/// Analiza las transacciones del usuario y detecta hacia dónde se está
/// desviando su dinero comparando el mes en curso con su propio historial.
///
/// Es lógica pura (sin Flutter ni plugins) para poder probarla fácilmente.
class SpendingDeviationDetector {
  const SpendingDeviationDetector({
    this.historyMonths = 3,
    this.spikeRatio = 1.3,
    this.paceRatio = 1.25,
    this.paceMinDay = 7,
    this.antMinCount = 8,
    this.antShareOfMonth = 0.10,
    this.antSmallShareOfReference = 0.02,
    this.concentrationShare = 0.5,
    this.concentrationMinExpenses = 5,
  });

  /// Meses previos que forman la línea base.
  final int historyMonths;

  /// Una categoría "se dispara" si supera su promedio en este factor.
  final double spikeRatio;

  /// El ritmo del mes preocupa si la proyección supera el promedio en este factor.
  final double paceRatio;

  /// Día mínimo del mes para proyectar (antes hay demasiado ruido).
  final int paceMinDay;

  /// Número mínimo de gastos pequeños para hablar de gastos hormiga.
  final int antMinCount;

  /// Parte del gasto mensual que deben sumar los gastos hormiga.
  final double antShareOfMonth;

  /// Un gasto es "pequeño" si no supera esta fracción del gasto mensual de referencia.
  final double antSmallShareOfReference;

  /// Parte del gasto del mes que debe concentrar un solo concepto.
  final double concentrationShare;

  /// Gastos mínimos en el mes antes de evaluar la concentración.
  final int concentrationMinExpenses;

  List<SpendingDeviation> detect(
    List<TransactionEntity> transactions, {
    required DateTime now,
    String currencySymbol = '',
  }) {
    final active = transactions.where((t) => t.deletedAt == null).toList();
    final monthStart = DateTime(now.year, now.month);
    final monthKey = _monthKey(now);
    String money(double v) => '$currencySymbol${v.toStringAsFixed(0)}';

    final currentExpenses =
        active
            .where(
              (t) =>
                  t.type == TransactionType.expense &&
                  !t.createdAt.isBefore(monthStart) &&
                  !t.createdAt.isAfter(now),
            )
            .toList();
    if (currentExpenses.isEmpty) return const [];

    final currentIncome = active
        .where(
          (t) =>
              t.type == TransactionType.income &&
              !t.createdAt.isBefore(monthStart) &&
              !t.createdAt.isAfter(now),
        )
        .fold<double>(0, (sum, t) => sum + t.amount);
    final currentTotal = _sum(currentExpenses);
    final currentByGroup = _byGroup(currentExpenses);

    // Línea base: sólo meses previos en los que el usuario registró gastos,
    // para no diluir el promedio de quien recién empieza a usar la app.
    final history = <Map<String, double>>[];
    for (var i = 1; i <= historyMonths; i++) {
      final start = DateTime(now.year, now.month - i);
      final end = DateTime(now.year, now.month - i + 1);
      final monthExpenses =
          active
              .where(
                (t) =>
                    t.type == TransactionType.expense &&
                    !t.createdAt.isBefore(start) &&
                    t.createdAt.isBefore(end),
              )
              .toList();
      if (monthExpenses.isNotEmpty) history.add(_byGroup(monthExpenses));
    }
    final hasHistory = history.isNotEmpty;
    final baselineTotal =
        hasHistory
            ? history.fold<double>(
                  0,
                  (sum, m) => sum + m.values.fold<double>(0, (a, b) => a + b),
                ) /
                history.length
            : 0.0;

    final deviations = <SpendingDeviation>[];

    // 1. Gastar más de lo que se gana.
    if (currentIncome > 0 && currentTotal > currentIncome) {
      deviations.add(
        SpendingDeviation(
          key: 'spendingAboveIncome|$monthKey',
          type: SpendingDeviationType.spendingAboveIncome,
          severity: 3,
          title: '🚨 Estás gastando más de lo que ganas',
          body:
              'Este mes llevas ${money(currentTotal)} en gastos y ${money(currentIncome)} en ingresos. '
              'Cubrir la diferencia suele terminar en deudas: revisa qué gastos puedes pausar esta semana.',
        ),
      );
    }

    // 2. Categorías que se disparan respecto a su promedio.
    final spiking = <String>{};
    if (hasHistory && baselineTotal > 0) {
      currentByGroup.forEach((group, current) {
        final avg =
            history.fold<double>(0, (sum, m) => sum + (m[group] ?? 0)) /
            history.length;
        final label = _label(group);
        if (avg > 0) {
          final excess = current - avg;
          if (current >= avg * spikeRatio && excess >= baselineTotal * 0.05) {
            spiking.add(group);
            final pct = ((current / avg - 1) * 100).round();
            deviations.add(
              SpendingDeviation(
                key: 'categorySpike|$monthKey|$group',
                type: SpendingDeviationType.categorySpike,
                severity: 2,
                group: group,
                title: '📈 Tu gasto en $label se disparó',
                body:
                    'Llevas ${money(current)} este mes, un $pct% más que tu promedio (${money(avg)}). '
                    'Ahí se están yendo ${money(excess)} extra: ponle un límite semanal a $label.',
              ),
            );
          }
        } else if (current >= baselineTotal * 0.15) {
          spiking.add(group);
          deviations.add(
            SpendingDeviation(
              key: 'categorySpike|$monthKey|$group',
              type: SpendingDeviationType.categorySpike,
              severity: 2,
              group: group,
              title: '🆕 Nuevo gasto importante: $label',
              body:
                  'Este mes apareció $label con ${money(current)}, algo que no tenías en meses anteriores. '
                  'Si no estaba planeado, decide si debe convertirse en un gasto fijo.',
            ),
          );
        }
      });
    }

    // 3. Ritmo de gasto del mes proyectado por encima del promedio.
    if (hasHistory && baselineTotal > 0 && now.day >= paceMinDay) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final projected = currentTotal / now.day * daysInMonth;
      if (projected >= baselineTotal * paceRatio) {
        final pct = ((projected / baselineTotal - 1) * 100).round();
        deviations.add(
          SpendingDeviation(
            key: 'monthlyPaceAboveAverage|$monthKey',
            type: SpendingDeviationType.monthlyPaceAboveAverage,
            severity: 2,
            title: '⏱️ A este ritmo cerrarás el mes gastando de más',
            body:
                'Proyectamos ${money(projected)} de gasto este mes, un $pct% más que tu promedio (${money(baselineTotal)}). '
                'Frenar ahora cuesta menos que recuperarse después.',
          ),
        );
      }
    }

    // 4. Gastos hormiga: muchos gastos pequeños que suman mucho.
    final reference =
        hasHistory && baselineTotal > 0 ? baselineTotal : currentTotal;
    final smallLimit = reference * antSmallShareOfReference;
    final small = currentExpenses.where((t) => t.amount <= smallLimit).toList();
    final smallTotal = _sum(small);
    if (small.length >= antMinCount &&
        smallTotal >= currentTotal * antShareOfMonth) {
      final yearly = smallTotal / now.day * 365;
      deviations.add(
        SpendingDeviation(
          key: 'antExpenses|$monthKey',
          type: SpendingDeviationType.antExpenses,
          severity: 1,
          title: '🐜 Cuidado con los gastos hormiga',
          body:
              '${small.length} gastos pequeños ya suman ${money(smallTotal)} este mes '
              '(${(smallTotal / currentTotal * 100).round()}% de tu gasto). '
              'A este ritmo serían ${money(yearly)} al año.',
        ),
      );
    }

    // 5. Un solo concepto concentra la mayor parte del gasto.
    if (currentExpenses.length >= concentrationMinExpenses &&
        currentByGroup.length > 1) {
      final top = currentByGroup.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      final share = top.value / currentTotal;
      if (share >= concentrationShare && !spiking.contains(top.key)) {
        final label = _label(top.key);
        deviations.add(
          SpendingDeviation(
            key: 'categoryConcentration|$monthKey|${top.key}',
            type: SpendingDeviationType.categoryConcentration,
            severity: 1,
            group: top.key,
            title: '🎯 La mayor parte de tu dinero va a $label',
            body:
                '${(share * 100).round()}% de tus gastos del mes (${money(top.value)}) se fueron a $label. '
                'Revisa si esa proporción refleja tus prioridades.',
          ),
        );
      }
    }

    deviations.sort((a, b) => b.severity.compareTo(a.severity));
    return deviations;
  }

  /// Agrupa por categoría (`#tag`) o, si no hay, por la nota normalizada.
  static String groupOf(TransactionEntity t) {
    final raw =
        (t.categoryId != null && t.categoryId!.trim().isNotEmpty)
            ? t.categoryId!
            : t.note;
    final normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return normalized.isEmpty ? 'otros' : normalized;
  }

  static Map<String, double> _byGroup(List<TransactionEntity> expenses) {
    final map = <String, double>{};
    for (final t in expenses) {
      final g = groupOf(t);
      map[g] = (map[g] ?? 0) + t.amount;
    }
    return map;
  }

  static double _sum(List<TransactionEntity> list) =>
      list.fold<double>(0, (sum, t) => sum + t.amount);

  static String _label(String group) => '"$group"';

  static String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
}
