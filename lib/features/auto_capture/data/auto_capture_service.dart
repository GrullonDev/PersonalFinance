import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:personal_finance/core/security/hive_encryption_service.dart';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/auto_capture/data/payment_capture_channel.dart';
import 'package:personal_finance/features/auto_capture/domain/merchant_categorizer.dart';
import 'package:personal_finance/features/auto_capture/domain/payment_notification_parser.dart';

/// Transacción lista para registrarse, detectada automáticamente.
class AutoCapturedTransaction {
  final String id;
  final String owner;
  final bool isSample;
  String get transactionId => 'capture_$id';
  bool get needsAmount => amount <= 0;
  final TransactionType type;
  final double amount;
  final String? currency;
  final String note;
  final String? category;
  final DateTime occurredAt;

  /// `Google Wallet`, `Apple Pay`, el banco, etc. Sólo informativo.
  final String sourceLabel;

  /// Texto original de la notificación; sirve para reconocer pagos a una
  /// deuda ("Pago a tarjeta Visa") aunque el comercio no se haya extraído.
  final String rawText;

  const AutoCapturedTransaction({
    this.id = '',
    this.owner = '',
    this.isSample = false,
    required this.type,
    required this.amount,
    required this.note,
    required this.occurredAt,
    required this.sourceLabel,
    this.category,
    this.currency,
    this.rawText = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner': owner,
    'isSample': isSample,
    'type': type.name,
    'amount': amount,
    'note': note,
    'category': category,
    'at': occurredAt.millisecondsSinceEpoch,
    'sourceLabel': sourceLabel,
    'currency': currency,
  };

  factory AutoCapturedTransaction.fromMap(Map row) => AutoCapturedTransaction(
    id: row['id'] as String,
    owner: row['owner'] as String,
    isSample: row['isSample'] == true,
    type: TransactionType.values.byName(row['type'] as String),
    amount: (row['amount'] as num).toDouble(),
    note: row['note'] as String,
    category: row['category'] as String?,
    sourceLabel: row['sourceLabel'] as String,
    occurredAt: DateTime.fromMillisecondsSinceEpoch(row['at'] as int),
    currency: row['currency'] as String?,
  );
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
    Box<Map>? inbox,
    Future<String?> Function(String merchant)? aiCategorizer,
    PaymentNotificationParser parser = const PaymentNotificationParser(),
    MerchantCategorizer categorizer = const MerchantCategorizer(),
  }) : _channel = channel,
       _prefs = prefs,
       _box = inbox,
       _aiCategorizer = aiCategorizer,
       _parser = parser,
       _categorizer = categorizer;

  static const String enabledPref = 'auto_capture_enabled';
  static const String seenPref = 'auto_capture_seen_fingerprints';
  static const String recentPref = 'auto_capture_recent_movements';
  static const Duration duplicateWindow = Duration(minutes: 3);

  final PaymentCaptureChannel _channel;
  final SharedPreferences _prefs;
  final Future<String?> Function(String merchant)? _aiCategorizer;
  final PaymentNotificationParser _parser;
  final MerchantCategorizer _categorizer;
  Box<Map>? _box;

  final _captured = StreamController<AutoCapturedTransaction>.broadcast();
  final _changes = StreamController<void>.broadcast();
  StreamSubscription<void>? _nativeSubscription;
  AppLifecycleListener? _lifecycle;
  Future<void> _tail = Future.value();
  String? _owner;

  String? get owner => _owner;
  Stream<void> get changes => _changes.stream;
  Stream<AutoCapturedTransaction> get captured => _captured.stream;

  List<AutoCapturedTransaction> get suggestions =>
      (_box?.values ?? const <Map>[])
          .where((r) => r['owner'] == owner && r['status'] == 'pending')
          .map(AutoCapturedTransaction.fromMap)
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  String _pref(String key, String uid) => '${key}_$uid';
  bool get isEnabled =>
      owner != null &&
      (_prefs.getBool(_pref(enabledPref, owner!)) ??
          _prefs.getBool(enabledPref) ??
          true);
  Set<String> get sources =>
      owner == null
          ? {}
          : (_prefs.getStringList(_pref('auto_capture_sources', owner!)) ??
                  const <String>[])
              .toSet();

  Future<T> _serial<T>(Future<T> Function() run) {
    final operation = _tail.then((_) => run());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  Future<void> setOwner(String? uid) {
    _owner = uid;
    _changes.add(null);
    return _serial(() async {
      if (_owner != uid) return;
      await _configure();
      // Earlier releases cached the full text in a global notification fingerprint.
      for (final key in [seenPref, recentPref]) {
        if (_prefs.containsKey(key)) await _prefs.remove(key);
      }
      if (uid == null || uid != _owner) return;
      await _open();
      if (uid != _owner) return;
      _changes.add(null);
      await _process(uid);
    });
  }

  Future<Box<Map>> _open() async =>
      _box ??= await Hive.openBox<Map>(
        'payment_capture_inbox_v1',
        encryptionCipher: await HiveEncryptionService.getCipher(),
      );

  Future<void> _configure() async {
    final uid = owner;
    await _channel.setOwner(isEnabled ? uid : null);
    if (uid != null && uid == owner && isEnabled) {
      await _channel.setSources(sources);
    }
  }

  Future<void> setEnabled({required bool enabled}) {
    final uid = owner;
    return _serial(() async {
      if (uid == null || uid != owner) return;
      if (!await _prefs.setBool(_pref(enabledPref, uid), enabled)) {
        throw StateError('No se pudo guardar la preferencia de captura');
      }
      await _configure();
      _changes.add(null);
      if (enabled) await _process(uid);
    });
  }

  Future<void> setSources(Set<String> sources) {
    final uid = owner;
    return _serial(() async {
      if (uid == null || uid != owner) return;
      if (!await _prefs.setStringList(
        _pref('auto_capture_sources', uid),
        sources.toList(),
      )) {
        throw StateError('No se pudieron guardar las fuentes');
      }
      if (uid == owner && isEnabled) await _channel.setSources(sources);
      _changes.add(null);
    });
  }

  Future<bool> isAccessGranted() => _channel.isAccessGranted();
  Future<void> openAccessSettings() => _channel.openAccessSettings();
  Future<bool> openShortcuts() => _channel.openShortcuts();
  Future<bool> isAutomationVerified() => _channel.isAutomationVerified();

  void start() {
    _nativeSubscription ??= _channel.onNewCapture.listen((_) => _refresh());
    _lifecycle ??= AppLifecycleListener(onResume: _refresh);
  }

  void _refresh() {
    unawaited(
      processPending().then<void>(
        (_) {},
        onError: (Object _, StackTrace __) {
          debugPrint('No se pudo actualizar la bandeja de capturas');
        },
      ),
    );
  }

  Future<List<AutoCapturedTransaction>> processPending() {
    final uid = owner;
    return _serial(
      () async => uid == null ? <AutoCapturedTransaction>[] : _process(uid),
    );
  }

  String _stableId(String uid, String nativeId) => const Uuid().v5(
    Namespace.url.value,
    jsonEncode(['payment-capture', uid, nativeId]),
  );

  Future<List<AutoCapturedTransaction>> _process(String uid) async {
    if (!isEnabled || uid != owner) return [];
    final box = await _open();
    final emitted = <AutoCapturedTransaction>[];
    for (final raw in await _channel.peekPending()) {
      if (uid != owner) break;
      if (raw.owner != uid || raw.id.isEmpty) continue;
      final id = _stableId(uid, raw.id);
      if (!box.containsKey(id)) {
        final tx = await _toTransaction(raw, id, uid);
        if (uid != owner) break;
        final row = <String, dynamic>{'owner': uid, 'status': 'ignored'};
        if (tx != null) {
          final duplicate = _duplicateOf(box, tx, raw);
          if (duplicate != null) {
            row['duplicateOf'] = duplicate;
          } else {
            row.addAll({
              ...tx.toMap(),
              'status': 'pending',
              'package': raw.packageName,
              'merchant': _merchant(raw),
              'card': _card(raw),
            });
          }
        }
        await box.put(id, row);
        if (uid == owner && tx != null && row['status'] == 'pending') {
          _captured.add(tx);
          _changes.add(null);
          emitted.add(tx);
        }
      }
      await box.flush();
      if (uid == owner) await _channel.acknowledge(raw.id);
    }
    return emitted;
  }

  String _merchant(RawPaymentCapture raw) =>
      (raw.merchant ??
              PaymentNotificationParser.extractMerchant(
                raw.text,
                title: raw.title,
              ))
          .trim()
          .toLowerCase();
  String? _currency(RawPaymentCapture raw) {
    final explicit = raw.currency?.trim().toUpperCase();
    if (explicit != null && RegExp(r'^[A-Z]{3}$').hasMatch(explicit)) return explicit;
    final token = RegExp(
      r'(?<![a-z])(?:US\$|GTQ|USD|MXN|EUR|COP|PEN|CLP|ARS|HNL|CRC|DOP|Q(?=\.?\s*\d)|[€£$])',
      caseSensitive: false,
    ).firstMatch('${raw.amount ?? ''} ${raw.text} ${raw.title}')?.group(0)?.toUpperCase();
    return switch (token) {
      'Q' => 'GTQ', '€' => 'EUR', '£' => 'GBP', r'US$' => 'USD', _ => token,
    };
  }

  String? _card(RawPaymentCapture raw) =>
      RegExp(r'[*•]{2,}\s*(\d{4})').firstMatch(raw.text)?.group(1);

  // Pair at most one alert per source pair. Multiple matching candidates
  // mean attribution is uncertain, so preserve the new suggestion.
  String? _duplicateOf(
    Box<Map> box,
    AutoCapturedTransaction tx,
    RawPaymentCapture raw,
  ) {
    final merchant = _merchant(raw);
    final currency = _currency(raw);
    if (tx.needsAmount || merchant.isEmpty || currency == null) return null;
    final paired =
        box.values
            .where((r) => r['owner'] == tx.owner)
            .map((r) => r['duplicateOf'])
            .whereType<String>()
            .toSet();
    final card = _card(raw);
    final candidates =
        box.values
            .where(
              (r) =>
                  r['owner'] == tx.owner &&
                  r['package'] != null &&
                  r['package'] != raw.packageName &&
                  !paired.contains(r['id']) &&
                  r['merchant'] == merchant &&
                  r['currency'] == currency &&
                  (card == null || r['card'] == null || card == r['card']) &&
                  r['type'] == tx.type.name &&
                  r['amount'] == tx.amount &&
                  ((r['at'] as int) - tx.occurredAt.millisecondsSinceEpoch)
                          .abs() <=
                      duplicateWindow.inMilliseconds,
            )
            .toList();
    return candidates.length == 1 ? candidates.single['id'] as String : null;
  }

  Future<void> addSample() {
    final uid = owner;
    return _serial(() async {
      if (uid == null || uid != owner) return;
      final box = await _open();
      final tx = AutoCapturedTransaction(
        id: _stableId(uid, 'sample-preview'),
        owner: uid,
        isSample: true,
        type: TransactionType.expense,
        amount: 25,
        note: 'Café de ejemplo',
        category: 'comida',
        occurredAt: DateTime.now(),
        sourceLabel: 'Ejemplo',
      );
      await box.put(tx.id, {...tx.toMap(), 'status': 'pending'});
      _changes.add(null);
    });
  }

  Future<void> dismiss(String id) => _finish(id, 'dismissed');
  Future<void> markSaved(String id) => _finish(id, 'saved');

  Future<void> _finish(String id, String status) {
    final uid = owner;
    return _serial(() async {
      final box = await _open();
      final row = box.get(id);
      if (uid == null ||
          uid != owner ||
          row == null ||
          row['owner'] != uid ||
          row['status'] != 'pending' ||
          (status == 'saved' && row['isSample'] == true)) {
        return;
      }
      await box.put(id, {...row, 'status': status});
      _changes.add(null);
    });
  }

  Future<AutoCapturedTransaction?> _toTransaction(
    RawPaymentCapture raw,
    String id,
    String uid,
  ) async {
    final ParsedPayment? parsed;
    final String sourceLabel;
    if (raw.source == 'shortcut') {
      final amount = PaymentNotificationParser.parseAmount(raw.amount ?? '');

      final kind = raw.kind?.toLowerCase();
      parsed = ParsedPayment(
        type:
            kind == 'ingreso' || kind == 'income'
                ? TransactionType.income
                : TransactionType.expense,
        amount: amount != null && amount.isFinite && amount > 0 ? amount : 0,
        merchant: (raw.merchant ?? '').trim(),
      );
      sourceLabel = 'Wallet';
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
      id: id,
      owner: uid,
      currency: _currency(raw),
      type: parsed.type,
      amount: parsed.amount,
      note: note,
      category: category,
      occurredAt: raw.postedAt,
      sourceLabel: sourceLabel,
      rawText: '${raw.title} ${raw.text}'.trim(),
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
    'ios.sms' ||
    'com.google.android.apps.messaging' ||
    'com.samsung.android.messaging' ||
    'com.android.mms' => 'SMS del banco',
    _ => 'tu banco',
  };

  Future<void> dispose() async {
    await _nativeSubscription?.cancel();
    _lifecycle?.dispose();
    await _tail;
    await _changes.close();
    await _captured.close();
  }
}
