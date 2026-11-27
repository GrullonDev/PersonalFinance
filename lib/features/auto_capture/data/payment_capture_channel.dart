import 'dart:async';

import 'package:flutter/services.dart';

/// Captura cruda recibida del lado nativo, antes de interpretarla.
class RawPaymentCapture {
  /// `notification` (Android) o `shortcut` (Atajos de iOS / enlace).
  final String id;
  final String? owner;
  final String source;
  final String packageName;
  final String title;
  final String text;

  /// Sólo para capturas de atajos: monto y comercio ya separados.
  final String? amount;
  final String? merchant;
  final String? currency;

  /// `gasto` o `ingreso`, si el atajo lo indicó.
  final String? kind;
  final DateTime postedAt;

  const RawPaymentCapture({
    this.id = '',
    this.owner,
    required this.source,
    required this.packageName,
    required this.title,
    required this.text,
    required this.postedAt,
    this.amount,
    this.merchant,
    this.currency,
    this.kind,
  });

  factory RawPaymentCapture.fromMap(Map<Object?, Object?> map) =>
      RawPaymentCapture(
        id: map['id'] as String? ?? '',
        owner: map['owner'] as String?,
        source: map['source'] as String? ?? 'notification',
        packageName: map['packageName'] as String? ?? '',
        title: map['title'] as String? ?? '',
        text: map['text'] as String? ?? '',
        amount: map['amount'] as String?,
        merchant: map['merchant'] as String?,
        currency: map['currency'] as String?,
        kind: map['kind'] as String?,
        postedAt: DateTime.fromMillisecondsSinceEpoch(
          (map['postedAt'] as num?)?.toInt() ?? 0,
        ),
      );

  /// Huella para no registrar dos veces la misma notificación.
  String get fingerprint =>
      '$source|$packageName|${postedAt.millisecondsSinceEpoch ~/ 60000}|$title|$text|$amount|$merchant';
}

/// Puente con el código nativo:
/// - Android: `PaymentNotificationListener` (lee notificaciones de pago).
/// - iOS: enlaces `personalfinance://pago?...` lanzados desde Atajos.
///
/// El lado nativo guarda las capturas en una cola; aquí se vacía.
class PaymentCaptureChannel {
  PaymentCaptureChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPaymentCaptured') _newCaptures.add(null);
    });
  }

  static const String channelName = 'personal_finance/payment_capture';

  final MethodChannel _channel;
  final StreamController<void> _newCaptures = StreamController.broadcast();

  /// Avisa cuando el lado nativo encoló una captura nueva.
  Stream<void> get onNewCapture => _newCaptures.stream;

  Future<List<RawPaymentCapture>> peekPending() async {
    final result = await _invoke<List<Object?>>('peekPending');
    return (result ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(RawPaymentCapture.fromMap)
        .toList();
  }

  Future<void> acknowledge(String id) =>
      _invoke<void>('acknowledge', {'id': id});
  Future<void> setOwner(String? owner) =>
      _invoke<void>('setCaptureOwner', {'owner': owner});
  Future<void> setSources(Set<String> sources) =>
      _invoke<void>('setSources', {'sources': sources.toList()});
  Future<bool> openShortcuts() async =>
      await _invoke<bool>('openShortcuts') ?? false;
  Future<bool> isAutomationVerified() async =>
      await _invoke<bool>('isAutomationVerified') ?? false;

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    }
  }

  /// Android: ¿el usuario concedió acceso a las notificaciones?
  /// iOS: siempre `true` (usa Atajos, no requiere permiso).
  Future<bool> isAccessGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessGranted') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Android: abre la pantalla del sistema para conceder el acceso.
  Future<void> openAccessSettings() async {
    try {
      await _channel.invokeMethod<void>('openAccessSettings');
    } on MissingPluginException {
      // Plataforma sin soporte.
    } on PlatformException {
      // Ignorado: el usuario puede abrir Ajustes manualmente.
    }
  }
}
