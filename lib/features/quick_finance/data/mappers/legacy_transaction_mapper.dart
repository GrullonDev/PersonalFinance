import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';

/// Mapper defensivo que normaliza documentos Firestore **legacy** al modelo
/// canónico [TransactionModel].
///
/// ## Problema
/// La colección `users/{uid}/transactions` fue escrita por dos sistemas
/// distintos con diferentes convenciones de nombres y tipos:
///
/// | Campo         | MVP (nuevo)      | Legacy (antiguo)                         |
/// |---------------|------------------|------------------------------------------|
/// | tipo          | `type`           | `tipo`                                   |
/// | monto         | `amount`         | `monto`                                  |
/// | descripción   | `note`           | `description` / `descripcion` / `nombre` / `title` |
/// | fecha alta    | `createdAt`      | `fecha` / `date` / `fecha_creacion`      |
/// | fecha edición | `updatedAt`      | `fecha_actualizacion`                    |
/// | soft-delete   | `deletedAt`      | `fecha_eliminacion`                      |
/// | categoría     | `categoryId`     | `category_id` / `categoria_id`           |
/// | valores type  | income/expense   | ingreso/gasto                            |
/// | tipo fecha    | ISO8601 String   | String YYYY-MM-DD / Timestamp / ms int   |
///
/// ## Reglas de fallback (aplicadas en [fromMap])
/// - `amount` inválido → `0.0`
/// - `type` desconocido → `TransactionType.expense`
/// - `note` vacío o nulo → `"Sin descripción"`
/// - `createdAt` inválido → `DateTime.now()`
/// - `updatedAt` ausente → `createdAt`
/// - `version` ausente → `1`
/// - `deviceId` ausente → `''`  (legacy no lo registra)
/// - `syncStatus` desde servidor → `SyncStatus.synced`
class LegacyTransactionMapper {
  const LegacyTransactionMapper._();

  // ── fromFirestore ─────────────────────────────────────────────────────────

  /// Construye un [TransactionModel] desde un [DocumentSnapshot] de Firestore.
  ///
  /// El campo `userId` se lee del propio documento; si no existe se usa
  /// cadena vacía (el repositorio puede sobreescribirlo con el uid autenticado).
  static TransactionModel fromFirestore(DocumentSnapshot doc) {
    // data() devuelve dynamic en la API sin genérico; cast defensivo
    final rawData = doc.data();
    final data =
        rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};

    final userId = _str(data['userId'] ?? data['user_id']) ?? '';
    return fromMap(data, documentId: doc.id, userId: userId);
  }

  // ── fromMap ───────────────────────────────────────────────────────────────

  /// Construye un [TransactionModel] desde un mapa arbitrario.
  ///
  /// [documentId] se usa como `id` si el mapa no tiene campo `id`.
  /// [userId] es obligatorio porque el legacy a veces no lo almacena.
  static TransactionModel fromMap(
    Map<String, dynamic> json, {
    required String userId,
    String? documentId,
  }) {
    // ── id ──────────────────────────────────────────────────────────────────
    // Prefiere campo "id" del documento; si falta usa docId del snapshot
    final id = _str(json['id']) ?? documentId ?? _generateId();

    // ── type ─────────────────────────────────────────────────────────────────
    // Aliases: type (MVP) / tipo (legacy)
    final type = _parseType(json['type'] ?? json['tipo']);

    // ── amount ───────────────────────────────────────────────────────────────
    // Aliases: amount (MVP) / monto (legacy)
    // Tipos posibles: double, int, String. Fallback: 0.0
    final amount = _parseAmount(json['amount'] ?? json['monto']);

    // ── note ─────────────────────────────────────────────────────────────────
    // Aliases: note / description / descripcion / nombre / title
    final note = _parseNote(
      json['note'] ??
          json['description'] ??
          json['descripcion'] ??
          json['nombre'] ??
          json['title'],
    );

    // ── categoryId ───────────────────────────────────────────────────────────
    // Aliases: categoryId / category_id / categoria_id
    final categoryId = _str(
      json['categoryId'] ?? json['category_id'] ?? json['categoria_id'],
    );

    // ── createdAt ─────────────────────────────────────────────────────────────
    // Aliases: createdAt / fecha / date / fecha_creacion
    // Tipos: ISO8601 String, YYYY-MM-DD String, Timestamp, int (ms)
    final createdAt =
        _parseDateTime(
          json['createdAt'] ??
              json['fecha'] ??
              json['date'] ??
              json['fecha_creacion'],
        ) ??
        DateTime.now(); // fallback: momento actual

    // ── updatedAt ─────────────────────────────────────────────────────────────
    // Aliases: updatedAt / fecha_actualizacion. Fallback: createdAt
    final updatedAt =
        _parseDateTime(json['updatedAt'] ?? json['fecha_actualizacion']) ??
        createdAt;

    // ── deletedAt ────────────────────────────────────────────────────────────
    // Aliases: deletedAt / fecha_eliminacion. Nullable
    final deletedAt = _parseDateTime(
      json['deletedAt'] ?? json['fecha_eliminacion'],
    );

    // ── version ──────────────────────────────────────────────────────────────
    final version = _parseInt(json['version']) ?? 1;

    // ── deviceId ─────────────────────────────────────────────────────────────
    // Legacy no registra deviceId; default vacío
    final deviceId = _str(json['deviceId'] ?? json['device_id']) ?? '';

    // ── syncStatus ───────────────────────────────────────────────────────────
    // Si viene de Firestore ya está sincronizado; solo respeta el campo si está
    final syncStatus = _parseSyncStatus(json['syncStatus']);

    return TransactionModel(
      id: id,
      userId: userId,
      type: type,
      amount: amount,
      note: note,
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      syncStatus: syncStatus,
      version: version,
      deviceId: deviceId,
    );
  }

  // ── Parsers privados ──────────────────────────────────────────────────────

  /// income/ingreso → income  |  expense/gasto/desconocido → expense
  static TransactionType _parseType(dynamic raw) {
    final s = (raw as String? ?? '').toLowerCase().trim();
    if (s == 'income' || s == 'ingreso') return TransactionType.income;
    // cualquier otro valor (incluido "gasto") cae a expense — más conservador
    return TransactionType.expense;
  }

  /// Convierte [raw] a double. Acepta num y String con punto o coma decimal.
  /// Devuelve 0.0 ante cualquier valor inválido o nulo.
  static double _parseAmount(dynamic raw) {
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String) {
      // normaliza coma decimal (ej. "35,50" → "35.50")
      return double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
    }
    // nulo o tipo inesperado → fallback 0.0
    return 0;
  }

  /// Devuelve el texto recortado o "Sin descripción" si está vacío/nulo.
  static String _parseNote(dynamic raw) {
    final s = raw is String ? raw.trim() : null;
    return (s == null || s.isEmpty) ? 'Sin descripción' : s;
  }

  /// Convierte [raw] a DateTime tolerando Timestamp, ISO8601, YYYY-MM-DD,
  /// int (milisegundos) y double. Devuelve null si no puede parsear.
  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;

    // Firestore Timestamp nativo
    if (raw is Timestamp) return raw.toDate();

    // milisegundos desde epoch (int o double)
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is double) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());

    if (raw is String) {
      // ISO8601 (ej. "2026-04-11T20:00:00.000") — tryParse lo soporta
      final iso = DateTime.tryParse(raw);
      if (iso != null) return iso;

      // YYYY-MM-DD → convertir a ISO para tryParse
      final dateOnly = DateTime.tryParse('${raw}T00:00:00.000');
      if (dateOnly != null) return dateOnly;
    }

    // tipo desconocido — no se puede parsear
    return null;
  }

  static SyncStatus _parseSyncStatus(dynamic raw) =>
      switch ((raw as String? ?? '').toLowerCase()) {
        'synced' => SyncStatus.synced,
        'failed' => SyncStatus.failed,
        'pending' => SyncStatus.pending,
        _ => SyncStatus.synced, // documentos del servidor → ya sincronizado
      };

  static String? _str(dynamic v) => v is String ? v : null;

  static int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// ID generado solo cuando el documento no tiene campo `id` ni `documentId`.
  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}
