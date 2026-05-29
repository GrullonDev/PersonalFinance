import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';

/// Un mapper tolerante a fallos que convierte documentos crudos de Firestore
/// que contienen esquema legacy hacia nuestro nuevo TransactionModel cerrado.
class LegacyTransactionMapper {
  /// Opción Ideal para Firestore: Úsalo cuando consumes la base de datos remotamente.
  static TransactionModel fromFirestore(DocumentSnapshot doc) {
    developer.log(
      'Interception Firestore Mapeo de legacy payload para: ${doc.id}',
      name: 'LegacyMapper',
    );
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return fromMap(data, documentId: doc.id);
  }

  /// Convierte un Map raw a un TransactionModel tolerante a fallos.
  static TransactionModel fromMap(
    Map<String, dynamic> json, {
    String? documentId,
  }) {
    // 1. Manejo Seguro del ID (Prioridad: id -> documentId)
    final id =
        json['id']?.toString() ??
        documentId ??
        'legacy_${DateTime.now().millisecondsSinceEpoch}';

    // 2. Manejo Seguro del Profile ID / User ID
    String userId = 'unknown_user';
    if (json.containsKey('profile_id') && json['profile_id'] != null) {
      userId = json['profile_id'].toString();
    } else if (json.containsKey('userId') && json['userId'] != null) {
      userId = json['userId'].toString();
    }

    // 3. Manejo del Monto (Prioridad: amount -> monto)
    double amount = 0;
    final rawAmount = json['amount'] ?? json['monto'];
    if (rawAmount != null) {
      if (rawAmount is num) {
        amount = rawAmount.toDouble();
      } else if (rawAmount is String) {
        // Limpiar para prevenir crasheos (ej. si mandan comas en el backend)
        final sanitized = rawAmount.replaceAll(',', '');
        amount = double.tryParse(sanitized) ?? 0.0;
      }
    } else {
      developer.log(
        'Problema grave: Monto no encontrado o inválido en el documento $id, forzando a 0.0',
        name: 'LegacyMapper',
      );
    }

    // 4. Manejo de Tipo de Transacción tolerante a fallos (Prioridad: type -> tipo)
    TransactionType type = TransactionType.expense; // default fallback
    final rawType = json['type'] ?? json['tipo'];
    if (rawType != null) {
      final t = rawType.toString().toLowerCase();
      if (t.startsWith('ingre') || t.startsWith('incom')) {
        type = TransactionType.income;
      } else if (t.startsWith('gast') ||
          t.startsWith('egres') ||
          t.startsWith('expens')) {
        type = TransactionType.expense;
      } else {
        developer.log(
          'Problema detectado: Tipo inválido "$t" en doc $id, infiriendo por signo',
          name: 'LegacyMapper',
        );
        type = amount >= 0 ? TransactionType.income : TransactionType.expense;
      }
    } else {
      developer.log(
        'Problema crítico: Tipo inexistente en doc $id, infiriendo por monto',
        name: 'LegacyMapper',
      );
      type = amount >= 0 ? TransactionType.income : TransactionType.expense;
    }

    // Si queremos el monto absoluto independientemente del signo
    amount = amount.abs();

    // 5. Manejo de la Descripción / Nota (Prioridad: note -> description -> descripcion -> title -> nombre)
    String note =
        (json['note'] ??
                json['description'] ??
                json['descripcion'] ??
                json['title'] ??
                json['nombre'] ??
                '')
            .toString()
            .trim();
    if (note.isEmpty) {
      developer.log(
        'Problema: Transacción $id no tiene texto o nombre, usando "Sin descripción"',
        name: 'LegacyMapper',
      );
      note = 'Sin descripción';
    }

    // 5.5 Manejo de Categoría (Prioridad: categoryId -> category_id -> categoria_id)
    final categoryId =
        (json['categoryId'] ?? json['category_id'] ?? json['categoria_id'])
            ?.toString();

    // 6. Manejo de Fechas (Prioridad: createdAt -> fecha_creacion -> date -> fecha)
    DateTime parsedDate = DateTime.now();
    final rawDate =
        json['createdAt'] ??
        json['fecha_creacion'] ??
        json['date'] ??
        json['fecha'];

    if (rawDate != null) {
      if (rawDate is Timestamp) {
        parsedDate = rawDate.toDate();
      } else if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      } else if (rawDate is int) {
        // Caso millisecond epoch
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
      }
    } else {
      developer.log(
        'Problema grave: Fecha inexistente en doc $id, forzando a DateTime.now()',
        name: 'LegacyMapper',
      );
    }

    // 7. Campos de Sincronización y Retención Local

    // UpdatedAt (Prioridad: updatedAt -> fecha_actualizacion -> fallback createdAt)
    DateTime updatedAt = parsedDate;
    final rawUpdated = json['updatedAt'] ?? json['fecha_actualizacion'];
    if (rawUpdated != null) {
      if (rawUpdated is Timestamp) {
        updatedAt = rawUpdated.toDate();
      } else if (rawUpdated is String) {
        updatedAt = DateTime.tryParse(rawUpdated) ?? parsedDate;
      } else if (rawUpdated is int) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(rawUpdated);
      }
    }

    // DeletedAt (Prioridad: deletedAt -> fecha_eliminacion)
    DateTime? deletedAt;
    final rawDeleted = json['deletedAt'] ?? json['fecha_eliminacion'];
    if (rawDeleted != null) {
      if (rawDeleted is Timestamp) {
        deletedAt = rawDeleted.toDate();
      } else if (rawDeleted is String) {
        deletedAt = DateTime.tryParse(rawDeleted);
      } else if (rawDeleted is int) {
        deletedAt = DateTime.fromMillisecondsSinceEpoch(rawDeleted);
      }
    }

    final syncStatusRaw = json['syncStatus'];
    SyncStatus status =
        SyncStatus.synced; // Asumimos que si viene de Firebase, ya está sync
    if (syncStatusRaw != null) {
      if (syncStatusRaw.toString() == 'pending') status = SyncStatus.pending;
      if (syncStatusRaw.toString() == 'failed') status = SyncStatus.failed;
    }

    final version = (json['version'] is int) ? json['version'] as int : 1;
    final deviceId = (json['deviceId'] ?? 'cloud_legacy_data').toString();

    return TransactionModel(
      id: id,
      userId: userId,
      type: type,
      amount: amount,
      note: note,
      createdAt: parsedDate,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      syncStatus: status,
      version: version,
      deviceId: deviceId,
      categoryId: categoryId,
    );
  }
}
