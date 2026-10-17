import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/auto_capture/domain/merchant_categorizer.dart';
import 'package:personal_finance/features/auto_capture/domain/payment_notification_parser.dart';

void main() {
  const parser = PaymentNotificationParser();
  const wallet = 'com.google.android.apps.walletnfcrel';
  const bank = 'com.banco.app';

  group('parseAmount', () {
    test('formatos comunes', () {
      expect(PaymentNotificationParser.parseAmount('Q45.50'), 45.5);
      expect(PaymentNotificationParser.parseAmount('Q 1,234.50'), 1234.5);
      expect(PaymentNotificationParser.parseAmount(r'$12,50'), 12.5);
      expect(PaymentNotificationParser.parseAmount('1.234,50 GTQ'), 1234.5);
      expect(PaymentNotificationParser.parseAmount('US\$ 9.99'), 9.99);
      expect(PaymentNotificationParser.parseAmount('Q1,500'), 1500);
      expect(PaymentNotificationParser.parseAmount('12.5'), 12.5);
      expect(PaymentNotificationParser.parseAmount('sin monto'), isNull);
    });
  });

  group('Google Wallet', () {
    test('el título es el comercio y se trata como gasto', () {
      final p = parser.parse(
        packageName: wallet,
        title: 'Starbucks',
        text: r'$4.75 con Visa ••1234',
      );
      expect(p, isNotNull);
      expect(p!.type, TransactionType.expense);
      expect(p.amount, 4.75);
      expect(p.merchant, 'Starbucks');
    });

    test('reembolso en la billetera es ingreso', () {
      final p = parser.parse(
        packageName: wallet,
        title: 'Amazon',
        text: r'Reembolso de $20.00 a tu Visa',
      );
      expect(p!.type, TransactionType.income);
      expect(p.amount, 20);
    });
  });

  group('Notificaciones bancarias', () {
    test('compra con comercio después de "en"', () {
      final p = parser.parse(
        packageName: bank,
        title: 'Banco',
        text: 'Compra aprobada por Q150.00 en SUPER LA TORRE el 25/09.',
      );
      expect(p!.type, TransactionType.expense);
      expect(p.amount, 150);
      expect(p.merchant, 'SUPER LA TORRE');
    });

    test('pagaste en inglés', () {
      final p = parser.parse(
        packageName: bank,
        title: 'Card alert',
        text: r'You paid $23.10 at Uber Eats',
      );
      expect(p!.type, TransactionType.expense);
      expect(p.merchant, 'Uber Eats');
    });

    test('transferencia recibida es ingreso', () {
      final p = parser.parse(
        packageName: bank,
        title: 'Transferencia recibida',
        text: 'Has recibido Q2,500.00 de JUAN PEREZ',
      );
      expect(p!.type, TransactionType.income);
      expect(p.amount, 2500);
    });

    test('depósito de planilla es ingreso', () {
      final p = parser.parse(
        packageName: bank,
        title: 'Banco',
        text: 'Depósito acreditado por Q6,000.00 a tu cuenta ****5678',
      );
      expect(p!.type, TransactionType.income);
    });

    test('compra que menciona devolución sigue siendo gasto', () {
      final p = parser.parse(
        packageName: bank,
        title: 'Banco',
        text: 'Compra por Q80.00 en ZARA. Política de devolución 30 días.',
      );
      expect(p!.type, TransactionType.expense);
    });
  });

  group('Bancos de Guatemala', () {
    test('monto con punto después de la Q', () {
      expect(PaymentNotificationParser.parseAmount('Q.150.00'), 150);
      expect(PaymentNotificationParser.parseAmount('Q. 1,250.75'), 1250.75);
    });

    test('se debitó de la cuenta es gasto', () {
      final p = parser.parse(
        packageName: bank,
        title: 'BI en Línea',
        text: 'Se debitó Q.250.00 de su cuenta ****1234 por pago en PRICESMART',
      );
      expect(p!.type, TransactionType.expense);
      expect(p.amount, 250);
    });

    test('transacción aprobada con tarjeta de crédito es gasto', () {
      final p = parser.parse(
        packageName: bank,
        title: 'Banco Industrial',
        text:
            'Transacción aprobada por Q85.40 en POLLO CAMPERO con tarjeta de crédito ****9876',
      );
      expect(p!.type, TransactionType.expense);
      expect(p.merchant, 'POLLO CAMPERO');
    });

    test('se acreditó a su cuenta es ingreso', () {
      final p = parser.parse(
        packageName: bank,
        title: 'Banrural',
        text: 'Se acreditó Q3,500.00 a su cuenta monetaria ****1111',
      );
      expect(p!.type, TransactionType.income);
      expect(p.amount, 3500);
    });

    test('transferencia a tu cuenta es ingreso', () {
      final p = parser.parse(
        packageName: bank,
        title: 'Banco',
        text: 'Transferencia a tu cuenta por Q500.00 de MARIA LOPEZ',
      );
      expect(p!.type, TransactionType.income);
    });

    test('pago a tarjeta es gasto aunque diga "acreditó"', () {
      final p = parser.parse(
        packageName: bank,
        title: 'Banco',
        text: 'Se acreditó su pago a tarjeta de crédito ****4321 por Q1,000.00',
      );
      expect(p!.type, TransactionType.expense);
      expect(p.amount, 1000);
    });

    test('pago de planilla es ingreso', () {
      final p = parser.parse(
        packageName: bank,
        title: 'Banco',
        text: 'Pago de planilla Q6,200.00 acreditado',
      );
      expect(p!.type, TransactionType.income);
    });
  });

  group('Se descarta si no hay certeza', () {
    test('transacción rechazada', () {
      expect(
        parser.parse(
          packageName: bank,
          title: 'Banco',
          text:
              'Transacción rechazada por Q300.00 en AMAZON: fondos insuficientes',
        ),
        isNull,
      );
    });

    test('recordatorio de pago mínimo', () {
      expect(
        parser.parse(
          packageName: bank,
          title: 'Banco',
          text:
              'Recuerda pagar tu tarjeta. Pago mínimo Q450.00, vence el 25/10',
        ),
        isNull,
      );
    });

    test('código de verificación', () {
      expect(
        parser.parse(
          packageName: bank,
          title: 'Banco',
          text: 'Tu código de verificación para la compra de Q99.00 es 123456',
        ),
        isNull,
      );
    });

    test('sin monto', () {
      expect(
        parser.parse(
          packageName: bank,
          title: 'Banco',
          text: 'Tu estado de cuenta ya está disponible',
        ),
        isNull,
      );
    });

    test('monto sin palabra clave fuera de billeteras', () {
      expect(
        parser.parse(
          packageName: bank,
          title: 'Promo',
          text: 'Obtén Q100 de descuento este fin de semana',
        ),
        isNull,
      );
    });
  });

  group('MerchantCategorizer', () {
    const c = MerchantCategorizer();

    test('asigna categorías por comercio', () {
      expect(c.categorize('Starbucks'), 'comida');
      expect(c.categorize('Uber Eats'), 'comida');
      expect(c.categorize('UBER *TRIP'), 'transporte');
      expect(c.categorize('SUPER LA TORRE'), 'supermercado');
      expect(c.categorize('NETFLIX.COM'), 'suscripciones');
      expect(c.categorize('Farmacia Galeno'), 'salud');
      expect(c.categorize('Tigo Guatemala'), 'servicios');
    });

    test('no confunde palabras dentro de otras', () {
      expect(c.categorize('Japan Store'), 'compras');
      expect(c.categorize('Ferretería Japan'), 'hogar');
    });

    test('ingresos', () {
      expect(
        c.categorize('Pago de planilla', type: TransactionType.income),
        'salario',
      );
    });

    test('desconocido devuelve null', () {
      expect(c.categorize('XYZ 123'), isNull);
      expect(c.categorize(''), isNull);
    });
  });
}
