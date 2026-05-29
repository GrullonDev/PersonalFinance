import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/mappers/legacy_transaction_mapper.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: llama fromMap con userId fijo para reducir boilerplate en tests
// ─────────────────────────────────────────────────────────────────────────────
TransactionModel _map(Map<String, dynamic> json, {String docId = 'doc_1'}) =>
    LegacyTransactionMapper.fromMap(json, documentId: docId, userId: 'u_test');

void main() {
  // ── 1. Schema MVP completo ────────────────────────────────────────────────

  group('Escenario 1 — schema MVP completo', () {
    late TransactionModel result;

    setUpAll(() {
      result = _map({
        'id': 'tx_mvp',
        'type': 'income',
        'amount': 1500.0,
        'note': 'salario',
        'createdAt': '2026-04-11T10:00:00.000',
        'updatedAt': '2026-04-11T11:00:00.000',
        'syncStatus': 'synced',
        'version': 3,
        'deviceId': 'pixel_9',
        'categoryId': 'cat_salary',
      });
    });

    test('id del mapa', () => expect(result.id, 'tx_mvp'));
    test('userId inyectado', () => expect(result.userId, 'u_test'));
    test('type income', () => expect(result.type, TransactionType.income));
    test('amount', () => expect(result.amount, 1500.0));
    test('note', () => expect(result.note, 'salario'));
    test(
      'createdAt ISO8601',
      () => expect(result.createdAt, DateTime(2026, 4, 11, 10)),
    );
    test(
      'updatedAt ISO8601',
      () => expect(result.updatedAt, DateTime(2026, 4, 11, 11)),
    );
    test(
      'syncStatus synced',
      () => expect(result.syncStatus, SyncStatus.synced),
    );
    test('version', () => expect(result.version, 3));
    test('deviceId', () => expect(result.deviceId, 'pixel_9'));
    test('categoryId', () => expect(result.categoryId, 'cat_salary'));
  });

  // ── 2. Schema legacy tipo / monto / descripcion / fecha ──────────────────

  group('Escenario 2 — schema legacy completo', () {
    late TransactionModel result;

    setUpAll(() {
      result = _map({
        'tipo': 'ingreso',
        'monto': 800.0,
        'descripcion': 'freelance',
        'fecha': '2026-04-01',
        'categoria_id': 'cat_work',
        'profile_id': '42',
      });
    });

    test(
      'tipo ingreso → income',
      () => expect(result.type, TransactionType.income),
    );
    test('monto mapeado', () => expect(result.amount, 800.0));
    test('descripcion → note', () => expect(result.note, 'freelance'));
    test('fecha YYYY-MM-DD → createdAt', () {
      expect(result.createdAt.year, 2026);
      expect(result.createdAt.month, 4);
      expect(result.createdAt.day, 1);
    });
    test(
      'updatedAt fallback = createdAt',
      () => expect(result.updatedAt, result.createdAt),
    );
    test(
      'categoria_id → categoryId',
      () => expect(result.categoryId, 'cat_work'),
    );
  });

  // ── 3. Alias "gasto" → expense ────────────────────────────────────────────

  group('Escenario 3 — tipo "gasto"', () {
    test('"gasto" → TransactionType.expense', () {
      final r = _map({'tipo': 'gasto', 'monto': 50.0, 'fecha': '2026-04-01'});
      expect(r.type, TransactionType.expense);
    });
  });

  // ── 4. type desconocido → fallback expense ────────────────────────────────

  group('Escenario 4 — type desconocido', () {
    test('"XYZ" → expense', () {
      final r = _map({'type': 'XYZ', 'amount': 10.0});
      expect(r.type, TransactionType.expense);
    });

    test('null → expense', () {
      final r = _map({'amount': 10.0});
      expect(r.type, TransactionType.expense);
    });
  });

  // ── 5. amount como int ────────────────────────────────────────────────────

  group('Escenario 5 — amount como int', () {
    test('int 250 → 250.0', () {
      final r = _map({'type': 'expense', 'amount': 250});
      expect(r.amount, 250.0);
      expect(r.amount, isA<double>());
    });
  });

  // ── 6. amount como String ─────────────────────────────────────────────────

  group('Escenario 6 — amount como String', () {
    test('"35.5" → 35.5', () {
      expect(_map({'amount': '35.5'}).amount, 35.5);
    });

    test('"35,50" (coma decimal) → 35.5', () {
      expect(_map({'amount': '35,50'}).amount, 35.5);
    });
  });

  // ── 7. amount inválido → 0.0 ──────────────────────────────────────────────

  group('Escenario 7 — amount inválido', () {
    test('null → 0.0', () {
      expect(_map({}).amount, 0.0);
    });

    test('"abc" → 0.0', () {
      expect(_map({'amount': 'abc'}).amount, 0.0);
    });

    test('monto: "no-es-numero" → 0.0', () {
      expect(_map({'monto': 'no-es-numero'}).amount, 0.0);
    });
  });

  // ── 8. note vacío / nulo → "Sin descripción" ─────────────────────────────

  group('Escenario 8 — note vacío', () {
    test('note: "" → "Sin descripción"', () {
      expect(_map({'amount': 10.0, 'note': ''}).note, 'Sin descripción');
    });

    test('note: "   " (solo espacios) → "Sin descripción"', () {
      expect(_map({'amount': 10.0, 'note': '   '}).note, 'Sin descripción');
    });

    test('sin campo note → "Sin descripción"', () {
      expect(_map({'amount': 10.0}).note, 'Sin descripción');
    });
  });

  // ── 9. Aliases de note ────────────────────────────────────────────────────

  group('Escenario 9 — aliases de note', () {
    test('"description" usado si no hay "note"', () {
      expect(_map({'amount': 10.0, 'description': 'gym'}).note, 'gym');
    });

    test('"nombre" legacy', () {
      expect(_map({'monto': 10.0, 'nombre': 'renta'}).note, 'renta');
    });

    test('"title" legacy', () {
      expect(
        _map({'amount': 10.0, 'title': 'suscripción'}).note,
        'suscripción',
      );
    });

    test('"note" tiene prioridad sobre "descripcion"', () {
      expect(
        _map({
          'amount': 10.0,
          'note': 'prioritario',
          'descripcion': 'otro',
        }).note,
        'prioritario',
      );
    });
  });

  // ── 10. createdAt inválido → DateTime.now() ───────────────────────────────

  group('Escenario 10 — createdAt inválido', () {
    test('null → fecha cercana a ahora', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final r = _map({'amount': 10.0});
      expect(r.createdAt.isAfter(before), isTrue);
    });

    test('"no-es-fecha" → fecha cercana a ahora', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final r = _map({'amount': 10.0, 'createdAt': 'no-es-fecha'});
      expect(r.createdAt.isAfter(before), isTrue);
    });
  });

  // ── 11. Aliases de createdAt ──────────────────────────────────────────────

  group('Escenario 11 — aliases de createdAt', () {
    test('"fecha" YYYY-MM-DD parseada', () {
      final r = _map({'fecha': '2026-03-15'});
      expect(r.createdAt.year, 2026);
      expect(r.createdAt.month, 3);
      expect(r.createdAt.day, 15);
    });

    test('"date" ISO8601', () {
      final r = _map({'date': '2026-01-20T08:30:00.000'});
      expect(r.createdAt, DateTime(2026, 1, 20, 8, 30));
    });

    test('"fecha_creacion" legacy', () {
      final r = _map({'fecha_creacion': '2025-12-25'});
      expect(r.createdAt.month, 12);
      expect(r.createdAt.day, 25);
    });
  });

  // ── 12. createdAt como milisegundos (int) ─────────────────────────────────

  group('Escenario 12 — createdAt como int (ms desde epoch)', () {
    test('int epoch → DateTime correcto', () {
      final dt = DateTime(2026, 4, 11, 12);
      final ms = dt.millisecondsSinceEpoch;
      final r = _map({'createdAt': ms});
      expect(r.createdAt.year, 2026);
      expect(r.createdAt.month, 4);
      expect(r.createdAt.day, 11);
    });
  });

  // ── 13. createdAt como Timestamp ─────────────────────────────────────────

  group('Escenario 13 — createdAt como Firestore Timestamp', () {
    test('Timestamp parseado correctamente', () {
      final dt = DateTime(2026, 4, 11, 15);
      final ts = Timestamp.fromDate(dt);
      final r = _map({'createdAt': ts});
      expect(r.createdAt.year, 2026);
      expect(r.createdAt.month, 4);
      expect(r.createdAt.day, 11);
      expect(r.createdAt.hour, 15);
    });
  });

  // ── 14. updatedAt ausente → igual a createdAt ────────────────────────────

  group('Escenario 14 — updatedAt ausente', () {
    test('sin updatedAt → updatedAt == createdAt', () {
      final r = _map({'createdAt': '2026-04-01T09:00:00.000'});
      expect(r.updatedAt, r.createdAt);
    });

    test('"fecha_actualizacion" usado como updatedAt', () {
      final r = _map({
        'createdAt': '2026-04-01T09:00:00.000',
        'fecha_actualizacion': '2026-04-02T10:00:00.000',
      });
      expect(r.updatedAt, DateTime(2026, 4, 2, 10));
    });
  });

  // ── 15. deletedAt aliases ─────────────────────────────────────────────────

  group('Escenario 15 — deletedAt', () {
    test('sin deletedAt → null', () {
      expect(_map({'amount': 10.0}).deletedAt, isNull);
    });

    test('"fecha_eliminacion" legacy', () {
      final r = _map({'fecha_eliminacion': '2026-04-05T00:00:00.000'});
      expect(r.deletedAt, isNotNull);
      expect(r.deletedAt!.day, 5);
    });

    test('"deletedAt" MVP', () {
      final r = _map({'deletedAt': '2026-04-10T00:00:00.000'});
      expect(r.deletedAt!.month, 4);
      expect(r.deletedAt!.day, 10);
    });
  });

  // ── 16. categoryId aliases ────────────────────────────────────────────────

  group('Escenario 16 — categoryId aliases', () {
    test('"category_id"', () {
      expect(_map({'category_id': 'cat_food'}).categoryId, 'cat_food');
    });

    test('"categoria_id"', () {
      expect(_map({'categoria_id': 'cat_trans'}).categoryId, 'cat_trans');
    });

    test('"categoryId" tiene prioridad', () {
      expect(
        _map({'categoryId': 'mvp_cat', 'categoria_id': 'leg_cat'}).categoryId,
        'mvp_cat',
      );
    });

    test('sin categoryId → null', () {
      expect(_map({'amount': 10.0}).categoryId, isNull);
    });
  });

  // ── 17. documentId como fallback de id ───────────────────────────────────

  group('Escenario 17 — documentId fallback', () {
    test('usa documentId cuando el mapa no tiene "id"', () {
      final r = _map({'amount': 10.0}, docId: 'firestore_doc_id');
      expect(r.id, 'firestore_doc_id');
    });

    test('"id" del mapa tiene prioridad sobre documentId', () {
      final r = _map({'id': 'map_id'}, docId: 'doc_id');
      expect(r.id, 'map_id');
    });
  });

  // ── 18. version ausente → 1 ──────────────────────────────────────────────

  group('Escenario 18 — version fallback', () {
    test('sin version → 1', () {
      expect(_map({'amount': 10.0}).version, 1);
    });

    test('version como int', () {
      expect(_map({'amount': 10.0, 'version': 5}).version, 5);
    });

    test('version como double → toInt', () {
      expect(_map({'amount': 10.0, 'version': 2.0}).version, 2);
    });
  });

  // ── 19. syncStatus desde Firestore ───────────────────────────────────────

  group('Escenario 19 — syncStatus', () {
    test('sin campo → synced (default servidor)', () {
      expect(_map({'amount': 10.0}).syncStatus, SyncStatus.synced);
    });

    test('"pending" → pending', () {
      expect(_map({'syncStatus': 'pending'}).syncStatus, SyncStatus.pending);
    });

    test('"failed" → failed', () {
      expect(_map({'syncStatus': 'failed'}).syncStatus, SyncStatus.failed);
    });

    test('valor desconocido → synced', () {
      expect(
        _map({'syncStatus': 'UNKNOWN_VALUE'}).syncStatus,
        SyncStatus.synced,
      );
    });
  });

  // ── 20. Documento completamente vacío ────────────────────────────────────

  group('Escenario 20 — mapa vacío', () {
    late TransactionModel result;

    setUpAll(() => result = _map({}));

    test('type → expense', () => expect(result.type, TransactionType.expense));
    test('amount → 0.0', () => expect(result.amount, 0.0));
    test(
      'note → "Sin descripción"',
      () => expect(result.note, 'Sin descripción'),
    );
    test('version → 1', () => expect(result.version, 1));
    test('deviceId → vacío', () => expect(result.deviceId, ''));
    test(
      'syncStatus → synced',
      () => expect(result.syncStatus, SyncStatus.synced),
    );
    test('categoryId → null', () => expect(result.categoryId, isNull));
    test('deletedAt → null', () => expect(result.deletedAt, isNull));
  });
}
