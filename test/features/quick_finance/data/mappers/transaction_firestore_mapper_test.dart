import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/mappers/transaction_firestore_mapper.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';

void main() {
  // ── Fixtures ──────────────────────────────────────────────────────────────

  const docId = 'doc_abc123';

  /// Documento Firestore con schema MVP (Quick Finance)
  final mvpDoc = {
    'id': 'tx_001',
    'userId': 'user_uid',
    'type': 'expense',
    'amount': 35.0,
    'note': 'cena',
    'createdAt': '2026-04-11T20:00:00.000',
    'updatedAt': '2026-04-11T20:00:00.000',
    'deletedAt': null,
    'syncStatus': 'synced',
    'version': 2,
    'deviceId': 'iphone_x',
    'categoryId': 'cat_food',
  };

  /// Documento Firestore con schema legacy (Backend)
  final legacyDoc = {
    'tipo': 'ingreso',
    'monto': 1500.0,
    'descripcion': 'salario',
    'fecha': '2026-04-01',
    'categoria_id': 'cat_salary',
    'es_recurrente': true,
    'profile_id': '42',
  };

  final entity = TransactionEntity(
    id: 'tx_new',
    userId: 'user_uid',
    type: TransactionType.income,
    amount: 500.0,
    note: 'bono',
    createdAt: DateTime(2026, 4, 11, 10, 0),
    updatedAt: DateTime(2026, 4, 11, 10, 0),
    syncStatus: SyncStatus.pending,
    version: 1,
    deviceId: 'pixel_7',
  );

  // ── fromFirestore — schema MVP ─────────────────────────────────────────────

  group('fromFirestore — schema MVP', () {
    late TransactionEntity result;
    late TransactionFirestoreExtras extras;

    setUp(() {
      final r = TransactionFirestoreMapper.fromFirestore(mvpDoc, docId: docId);
      result = r.entity;
      extras = r.extras;
    });

    test('id viene del campo "id" del documento', () {
      expect(result.id, 'tx_001');
    });

    test('userId mapeado', () {
      expect(result.userId, 'user_uid');
    });

    test('type "expense" → TransactionType.expense', () {
      expect(result.type, TransactionType.expense);
    });

    test('amount mapeado como double', () {
      expect(result.amount, 35.0);
    });

    test('note mapeada', () {
      expect(result.note, 'cena');
    });

    test('createdAt parseada desde ISO8601', () {
      expect(result.createdAt, DateTime(2026, 4, 11, 20, 0));
    });

    test('deletedAt null', () {
      expect(result.deletedAt, isNull);
    });

    test('syncStatus "synced" → SyncStatus.synced', () {
      expect(result.syncStatus, SyncStatus.synced);
    });

    test('version mapeado', () {
      expect(result.version, 2);
    });

    test('deviceId mapeado', () {
      expect(result.deviceId, 'iphone_x');
    });

    test('extras.categoryId recogido del schema MVP', () {
      expect(extras.categoryId, 'cat_food');
    });

    test('extras.isRecurring null si no está presente', () {
      expect(extras.isRecurring, isNull);
    });
  });

  // ── fromFirestore — schema MVP con type "income" ───────────────────────────

  group('fromFirestore — type income', () {
    test('"income" → TransactionType.income', () {
      final r = TransactionFirestoreMapper.fromFirestore(
        {...mvpDoc, 'type': 'income'},
        docId: docId,
      );
      expect(r.entity.type, TransactionType.income);
    });
  });

  // ── fromFirestore — schema legacy ─────────────────────────────────────────

  group('fromFirestore — schema legacy', () {
    late TransactionEntity result;
    late TransactionFirestoreExtras extras;

    setUp(() {
      final r = TransactionFirestoreMapper.fromFirestore(
        legacyDoc,
        docId: docId,
      );
      result = r.entity;
      extras = r.extras;
    });

    test('id cae back al docId cuando el campo id no existe', () {
      expect(result.id, docId);
    });

    test('"ingreso" → TransactionType.income', () {
      expect(result.type, TransactionType.income);
    });

    test('monto legacy mapeado a amount', () {
      expect(result.amount, 1500.0);
    });

    test('descripcion legacy mapeada a note', () {
      expect(result.note, 'salario');
    });

    test('fecha "YYYY-MM-DD" parseada a createdAt', () {
      expect(result.createdAt.year, 2026);
      expect(result.createdAt.month, 4);
      expect(result.createdAt.day, 1);
    });

    test('legacy sin deletedAt → deletedAt null', () {
      expect(result.deletedAt, isNull);
    });

    test('legacy → syncStatus synced (viene del server)', () {
      expect(result.syncStatus, SyncStatus.synced);
    });

    test('extras.categoryId desde "categoria_id"', () {
      expect(extras.categoryId, 'cat_salary');
    });

    test('extras.isRecurring desde "es_recurrente"', () {
      expect(extras.isRecurring, isTrue);
    });

    test('extras.profileId desde "profile_id"', () {
      expect(extras.profileId, '42');
    });

    test('"gasto" → TransactionType.expense', () {
      final r = TransactionFirestoreMapper.fromFirestore(
        {...legacyDoc, 'tipo': 'gasto'},
        docId: docId,
      );
      expect(r.entity.type, TransactionType.expense);
    });
  });

  // ── fromFirestore — docId fallback ─────────────────────────────────────────

  group('fromFirestore — fallback de id', () {
    test('usa docId cuando el campo "id" no existe en el mapa', () {
      final data = {...mvpDoc}..remove('id');
      final r = TransactionFirestoreMapper.fromFirestore(data, docId: 'fallback_id');
      expect(r.entity.id, 'fallback_id');
    });
  });

  // ── fromFirestore — syncStatus values ─────────────────────────────────────

  group('fromFirestore — syncStatus', () {
    for (final entry in {
      'pending': SyncStatus.pending,
      'synced': SyncStatus.synced,
      'failed': SyncStatus.failed,
      'unknown': SyncStatus.pending, // valor desconocido → pending
      null: SyncStatus.pending,
    }.entries) {
      test('syncStatus "${entry.key}" → ${entry.value}', () {
        final r = TransactionFirestoreMapper.fromFirestore(
          {...mvpDoc, 'syncStatus': entry.key},
          docId: docId,
        );
        expect(r.entity.syncStatus, entry.value);
      });
    }
  });

  // ── toFirestore ────────────────────────────────────────────────────────────

  group('toFirestore', () {
    late Map<String, dynamic> result;

    setUp(() {
      result = TransactionFirestoreMapper.toFirestore(entity);
    });

    test('id incluido', () => expect(result['id'], 'tx_new'));
    test('userId incluido', () => expect(result['userId'], 'user_uid'));
    test('type "income"', () => expect(result['type'], 'income'));
    test('amount', () => expect(result['amount'], 500.0));
    test('note', () => expect(result['note'], 'bono'));

    test('createdAt como ISO8601', () {
      expect(result['createdAt'], isA<String>());
      expect(DateTime.tryParse(result['createdAt'] as String), isNotNull);
    });

    test('deletedAt null cuando no hay soft-delete', () {
      expect(result['deletedAt'], isNull);
    });

    test('syncStatus "pending"', () {
      expect(result['syncStatus'], 'pending');
    });

    test('version', () => expect(result['version'], 1));
    test('deviceId', () => expect(result['deviceId'], 'pixel_7'));

    test('categoryId ausente si no se pasa extras', () {
      expect(result.containsKey('categoryId'), isFalse);
    });
  });

  group('toFirestore — con extras', () {
    test('categoryId incluido cuando extras lo tiene', () {
      final result = TransactionFirestoreMapper.toFirestore(
        entity,
        extras: const TransactionFirestoreExtras(
          categoryId: 'cat_abc',
          isRecurring: false,
          profileId: '7',
        ),
      );
      expect(result['categoryId'], 'cat_abc');
      expect(result['isRecurring'], false);
      expect(result['profileId'], '7');
    });
  });

  // ── toFirestore — syncStatus strings ──────────────────────────────────────

  group('toFirestore — syncStatus serialization', () {
    for (final entry in {
      SyncStatus.pending: 'pending',
      SyncStatus.synced: 'synced',
      SyncStatus.failed: 'failed',
    }.entries) {
      test('${entry.key} → "${entry.value}"', () {
        final e = TransactionEntity(
          id: 'x',
          userId: 'u',
          type: TransactionType.expense,
          amount: 1.0,
          note: '',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          syncStatus: entry.key,
          version: 1,
          deviceId: 'd',
        );
        final map = TransactionFirestoreMapper.toFirestore(e);
        expect(map['syncStatus'], entry.value);
      });
    }
  });

  // ── Round-trip ─────────────────────────────────────────────────────────────

  group('round-trip toFirestore → fromFirestore', () {
    test('entidad sobrevive serialización y deserialización', () {
      final map = TransactionFirestoreMapper.toFirestore(entity);
      final r = TransactionFirestoreMapper.fromFirestore(map, docId: entity.id);

      expect(r.entity.id, entity.id);
      expect(r.entity.userId, entity.userId);
      expect(r.entity.type, entity.type);
      expect(r.entity.amount, entity.amount);
      expect(r.entity.note, entity.note);
      expect(r.entity.syncStatus, entity.syncStatus);
      expect(r.entity.version, entity.version);
      expect(r.entity.deviceId, entity.deviceId);
    });
  });
}
