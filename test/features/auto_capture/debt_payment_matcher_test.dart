import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/auto_capture/domain/debt_payment_matcher.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';

Debt _debt(String id, String name, {double balance = 5000}) => Debt(
  id: id,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  deviceId: 'test',
  version: 1,
  name: name,
  currentBalance: balance,
  originalAmount: 10000,
  interestRate: 0,
  nextPaymentDate: DateTime(2026, 11),
  minimumPayment: 100,
);

void main() {
  const matcher = DebtPaymentMatcher();
  final visa = _debt('1', 'Visa BI');
  final moto = _debt('2', 'Préstamo moto');
  final card = _debt('3', 'Tarjeta 4321');

  test('pago a tarjeta con el nombre de la deuda', () {
    expect(
      matcher.match('Pago a tarjeta VISA BI por Q500.00', [visa, moto]),
      visa,
    );
  });

  test('cuota de préstamo por palabra significativa', () {
    expect(
      matcher.match('Se debitó Q850.00 cuota préstamo MOTO', [visa, moto]),
      moto,
    );
  });

  test('reconoce los últimos 4 dígitos de la tarjeta', () {
    expect(
      matcher.match(
        'Se acreditó su pago a tarjeta de crédito ****4321 por Q1,000.00',
        [visa, card],
      ),
      card,
    );
  });

  test('una compra con la tarjeta no es un pago a la deuda', () {
    expect(
      matcher.match('Compra por Q80.00 en ZARA con tarjeta VISA BI', [visa]),
      isNull,
    );
  });

  test('pago genérico a tarjeta con una sola deuda', () {
    expect(matcher.match('Pago a tarjeta de crédito Q300', [visa]), visa);
  });

  test('pago genérico con varias deudas no adivina', () {
    expect(
      matcher.match('Pago a tarjeta de crédito Q300', [visa, moto]),
      isNull,
    );
  });

  test('pago de servicios no toca deudas', () {
    expect(matcher.match('Pago de luz EEGSA Q250', [visa]), isNull);
  });

  test('deudas saldadas se ignoran', () {
    expect(
      matcher.match('Pago a tarjeta VISA BI', [
        _debt('1', 'Visa BI', balance: 0),
      ]),
      isNull,
    );
  });
}
