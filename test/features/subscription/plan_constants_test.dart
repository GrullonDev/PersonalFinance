import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/subscription/domain/entities/subscription_entity.dart';
import 'package:personal_finance/features/subscription/domain/subscription_constants.dart';

void main() {
  test('Pro cuesta US\$2.99 al mes', () {
    expect(PlanPricing.proMonthly, 2.99);
    expect(PlanPricing.proMonthlyFormatted, r'$2.99');
  });

  test('el plan gratis permite 2 presupuestos y 2 metas', () {
    expect(PlanLimits.free.maxBudgets, 2);
    expect(PlanLimits.free.maxGoals, 2);
    expect(PlanLimits.pro.isUnlimited(PlanLimits.pro.maxBudgets), isTrue);
  });

  test('Pro sólo ofrece funciones que existen', () {
    expect(
      PlanFeatures.proFeatures,
      isNot(
        anyOf(
          contains(PlanFeature.homeWidget),
          contains(PlanFeature.recurringTransactions),
          contains(PlanFeature.unlimitedAccounts),
        ),
      ),
    );
    for (final lang in ['es', 'en']) {
      final labels = PlanFeatureLabels.labelsFor(lang);
      for (final f in PlanFeatures.proFeatures) {
        expect(labels[f], isNotNull, reason: '$lang sin texto para $f');
      }
    }
  });

  test('la comparación refleja los límites del plan gratis', () {
    final rows = PlanComparison.rows('es');
    final budgets = rows.firstWhere((r) => r.label == 'Presupuestos');
    expect(budgets.free, '${PlanLimits.free.maxBudgets}');
    expect(budgets.pro, 'Ilimitados');
    // Todo lo del plan gratis también está en Pro.
    expect(rows.every((r) => r.pro != null), isTrue);
    expect(PlanComparison.rows('en'), hasLength(rows.length));
  });
}
