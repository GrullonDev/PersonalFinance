import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/auto_capture/data/payment_capture_channel.dart';
import 'package:personal_finance/features/auto_capture/domain/merchant_categorizer.dart';
import 'package:personal_finance/features/auto_capture/domain/payment_notification_parser.dart';

/// Transacción lista para registrarse, detectada automáticamente.
class AutoCapturedTransaction {
  final TransactionType type;
  final double amount;
  final String note;
  final String? category;
  final DateTime occurredAt;

  /// `Google Wallet`, `Apple Pay`, el banco, etc. Sólo informativo.
  final String sourceLabel;

  const AutoCapturedTransaction({
    required this.type,
    required this.amount,
    required this.note,
    required this.occurredAt,
    required this.sourceLabel,
    this.category,
  });
}

/// Convierte las capturas nativas (notificaciones de pago en Android,
/// atajos de Apple Pay en iOS) en transacciones con comercio y categoría.
///
/// Si una notificación no se entiende con seguridad se descarta: el usuario
/// registra ese movimiento manualmente.
class AutoCaptureService {
  AutoCaptureService({
    required PaymentCaptureChannel channel,
    required SharedPreferences prefs,
    Future<String?> Function(String merchant)? aiCategorizer,
    PaymentNotificationParser parser = const PaymentNotificationParser(),
    MerchantCategorizer categorizer = const MerchantCategorizer(),
  }) : _channel = channel,
       _prefs = prefs,
       _aiCategorizer = aiCategorizer,
       _parser = parser,
       _categorizer = categorizer;

  static const String enabledPref = 'auto_capture_enabled';
  static const String seenPref = 'auto_capture_seen_fingerprints';
  static const int _maxSeen = 200;

  final PaymentCaptureChannel _channel;
  final SharedPreferences _prefs;
  final Future<String?> Function(String merchant)? _aiCategorizer;
  final PaymentNotificationParser _parser;
  final MerchantCategorizer _categorizer;

  final StreamController<AutoCapturedTransaction> _captured =
      StreamController.broadcast();
  StreamSubscription<void>? _nativeSubscription;
  AppLifecycleListener? _lifecycle;
  bool _processing = false;

  /// Transacciones detectadas; `QuickFinanceBloc` las registra.
  Stream<AutoCapturedTransaction> get captured => _captured.stream;

  bool get isEnabled => _prefs.getBool(enabledPref) ?? true;

  Future<void> setEnabled({required bool enabled}) =>
      _prefs.setBool(enabledPref, enabled);

  Future<bool> isAccessGranted() => _channel.isAccessGranted();

  Future<void> openAccessSettings() => _channel.openAccessSettings();

  /// Empieza a escuchar capturas nuevas y la vuelta de la app a primer plano.
  void start() {
    _nativeSubscription ??= _channel.onNewCapture.listen(
      (_) => processPending(),
    );
    _lifecycle ??= AppLifecycleListener(onResume: processPending);
  }

  /// Vacía la cola nativa y emite las transacciones reconocidas.
  /// No hace nada si nadie está escuchando (p. ej. sin sesión iniciada),
  /// así las capturas esperan en la cola nativa.
  Future<List<AutoCapturedTransaction>> processPending() async {
    if (_processing || !_captured.hasListener || !isEnabled) return const [];
    _processing = true;
    try {
      final raws = await _channel.drainPending();
      final seen =
          (_prefs.getStringList(seenPref) ?? const <String>[]).toList();
      final emitted = <AutoCapturedTransaction>[];

      for (final raw in raws) {
        final fingerprint = raw.fingerprint;
        if (seen.contains(fingerprint)) continue;
        seen.add(fingerprint);

        final tx = await _toTransaction(raw);
        if (tx == null) continue;
        _captured.add(tx);
        emitted.add(tx);
      }

      if (seen.length > _maxSeen) seen.removeRange(0, seen.length - _maxSeen);
      await _prefs.setStringList(seenPref, seen);
      return emitted;
    } catch (e) {
      debugPrint('AutoCaptureService: error procesando capturas: $e');
      return const [];
    } finally {
      _processing = false;
    }
  }

  Future<AutoCapturedTransaction?> _toTransaction(RawPaymentCapture raw) async {
    final ParsedPayment? parsed;
    final String sourceLabel;
    if (raw.source == 'shortcut') {
      final amount = PaymentNotificationParser.parseAmount(raw.amount ?? '');
      if (amount == null || amount <= 0) return null;
      final kind = raw.kind?.toLowerCase();
      parsed = ParsedPayment(
        type:
            kind == 'ingreso' || kind == 'income'
                ? TransactionType.income
                : TransactionType.expense,
        amount: amount,
        merchant: (raw.merchant ?? '').trim(),
      );
      sourceLabel = 'Apple Pay';
    } else {
      parsed = _parser.parse(
        packageName: raw.packageName,
        title: raw.title,
        text: raw.text,
      );
      sourceLabel = _labelFor(raw.packageName);
    }
    if (parsed == null) return null;

    final category = await _categorize(parsed, raw);
    final note =
        parsed.merchant.isNotEmpty
            ? parsed.merchant
            : parsed.type == TransactionType.income
            ? 'Ingreso ($sourceLabel)'
            : 'Pago con $sourceLabel';

    return AutoCapturedTransaction(
      type: parsed.type,
      amount: parsed.amount,
      note: note,
      category: category,
      occurredAt: raw.postedAt,
      sourceLabel: sourceLabel,
    );
  }

  Future<String?> _categorize(
    ParsedPayment parsed,
    RawPaymentCapture raw,
  ) async {
    final source =
        parsed.type == TransactionType.income
            ? '${raw.title} ${raw.text} ${parsed.merchant}'
            : parsed.merchant;
    final local = _categorizer.categorize(source, type: parsed.type);
    if (local != null) return local;
    if (parsed.type == TransactionType.income) return 'ingresos';

    final ai = _aiCategorizer;
    if (ai == null || parsed.merchant.isEmpty) return null;
    try {
      final result = await ai(
        parsed.merchant,
      ).timeout(const Duration(seconds: 5));
      final normalized = result?.trim().toLowerCase();
      if (normalized == null || normalized.isEmpty || normalized == 'otros') {
        return null;
      }
      return normalized;
    } catch (_) {
      return null;
    }
  }

  static String _labelFor(String packageName) => switch (packageName) {
    'com.google.android.apps.walletnfcrel' => 'Google Wallet',
    'com.google.android.apps.nbu.paisa.user' => 'Google Pay',
    'com.samsung.android.spay' => 'Samsung Wallet',
    _ => 'tu banco',
  };

  Future<void> dispose() async {
    await _nativeSubscription?.cancel();
    _lifecycle?.dispose();
    await _captured.close();
  }
}
